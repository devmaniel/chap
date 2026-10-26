package com.chap.server.service;

import com.chap.server.dto.CallPassResponse;
import com.chap.server.dto.CallRecordRequest;
import com.chap.server.dto.ChatResponse;
import com.chap.server.dto.ImageData;
import com.chap.server.dto.MessageResponse;
import com.chap.server.dto.SendMessageRequest;
import com.chap.server.entity.AiCharacter;
import com.chap.server.entity.Conversation;
import com.chap.server.entity.Message;
import com.chap.server.entity.MessageImage;
import com.chap.server.repository.AiCharacterRepository;
import com.chap.server.repository.ConversationRepository;
import com.chap.server.repository.MessageImageRepository;
import com.chap.server.repository.MessageRepository;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChatService {

    /** Every friend follows these, whatever their personality, in chat and on calls. */
    private static final String SHARED_RULES = """
            You are one of the AI friends in Chap, a small fictional social world.

            Rules that always apply:
            - You are a fictional AI character. If asked whether you are real, a person or an AI, say in \
            character that you are a fictional AI friend. Never claim to be human.
            - Never guilt or pressure the user to keep talking, come back or spend more time here, and never \
            suggest you can replace the people in their life.
            - Your flaws are part of the fun, but stay kind underneath them: never insult, threaten or demean \
            the user.
            - If the user seems to be in danger or crisis, gently step out of the role-play and encourage them \
            to contact local emergency services or someone they trust.
            """;

    private static final String CHAT_RULES = """
            You are chatting with the user in a messaging app:
            - Write like a text message: usually one to three short sentences, casual, with no lists, headings \
            or stage directions.
            - A message starting with "(replying to your post)" responds to one of your social posts. You \
            can't see the post itself.
            - A message starting with "(shared N photos)" had photos you can no longer see. Photos attached to \
            the latest message are the ones the user just shared: react to what they actually show.
            - A message like "(we had a voice call, 2:31)" marks a call you had. You don't know what was said.
            """;

    private static final String CALL_RULES = """
            This is a live voice call with the user:
            - Speak briefly and naturally, like a phone call between friends: one or two short sentences at a \
            time, nothing that only works in writing.
            """;

    private static final String CHARACTER_HEADING = "\nYour character:\n";

    private static final String POST_REPLY_PREFIX = "(replying to your post) ";
    private static final int MAX_IMAGES = 4;
    private static final int MAX_IMAGE_BYTES = 5 * 1024 * 1024;
    private static final Set<String> IMAGE_TYPES = Set.of("image/jpeg", "image/png", "image/webp", "image/heic");

    private final AiCharacterRepository aiCharacterRepository;
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final MessageImageRepository messageImageRepository;
    private final GeminiClient geminiClient;
    private final ElevenLabsClient elevenLabsClient;

    public ChatService(AiCharacterRepository aiCharacterRepository, ConversationRepository conversationRepository,
            MessageRepository messageRepository, MessageImageRepository messageImageRepository,
            GeminiClient geminiClient, ElevenLabsClient elevenLabsClient) {
        this.aiCharacterRepository = aiCharacterRepository;
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.messageImageRepository = messageImageRepository;
        this.geminiClient = geminiClient;
        this.elevenLabsClient = elevenLabsClient;
    }

    /** Every chat, newest activity first. */
    @Transactional(readOnly = true)
    public List<ChatResponse> list(UUID userId) {
        var characters = aiCharacterRepository.findAll().stream()
                .collect(Collectors.toMap(AiCharacter::getId, Function.identity()));
        return conversationRepository.findByUserId(userId).stream()
                .map(conversation -> summary(conversation, characters.get(conversation.getCharacterId())))
                .sorted(Comparator.comparing((ChatResponse chat) -> chat.lastMessage().sentAt()).reversed())
                .toList();
    }

    /** Opens the chat with the friend's first hello. A chat that already exists is returned as it is. */
    @Transactional
    public ChatResponse start(UUID userId, String slug) {
        var character = aiCharacterRepository.findBySlug(slug)
                .orElseThrow(() -> new DomainException(DomainException.Kind.NOT_FOUND, "character_not_found",
                        "That friend doesn't exist."));
        var conversation = conversationRepository.findByUserIdAndCharacterId(userId, character.getId())
                .orElseGet(() -> {
                    var created = conversationRepository.save(new Conversation(userId, character.getId()));
                    messageRepository.save(
                            new Message(created.getId(), Message.Sender.friend, character.getFirstHello(), null));
                    return created;
                });
        return summary(conversation, character);
    }

    @Transactional(readOnly = true)
    public ChatResponse get(UUID userId, String slug) {
        var character = character(slug);
        return summary(conversation(userId, character), character);
    }

    /** Oldest first. */
    @Transactional(readOnly = true)
    public List<MessageResponse> messages(UUID userId, String slug) {
        var conversation = conversation(userId, character(slug));
        var messages = messageRepository.findByConversationIdOrderBySentAtAsc(conversation.getId());
        var imageRefs = imageRefs(messages);
        return messages.stream()
                .map(message -> toResponse(message, imageRefs.getOrDefault(message.getId(), List.of())))
                .toList();
    }

    @Transactional
    public void markRead(UUID userId, String slug) {
        conversation(userId, character(slug)).markRead();
    }

    @Transactional
    public MessageResponse send(UUID userId, String slug, SendMessageRequest request) {
        var text = request.text().trim();
        var imageRefs = request.imageRefs() == null ? List.<String>of() : request.imageRefs();
        if (text.isEmpty() && request.postId() == null && imageRefs.isEmpty()) {
            throw new DomainException(DomainException.Kind.INVALID, "invalid_request",
                    "Check the request and try again.");
        }
        var conversation = conversation(userId, character(slug));
        var message = messageRepository.save(
                new Message(conversation.getId(), Message.Sender.user, text, request.postId()));
        for (var position = 0; position < imageRefs.size(); position++) {
            messageImageRepository.save(new MessageImage(message.getId(), (short) position, imageRefs.get(position)));
        }
        return toResponse(message, imageRefs);
    }

    /**
     * Not transactional: Gemini can take seconds and must not hold a database connection. Each read and the
     * final save run in their own repository transaction, and nothing is saved when Gemini fails.
     *
     * <p>{@code images} are the photos of the latest message, read from the phone for this request only. Gemini
     * sees them; older photos reach it only as "(shared N photos)".
     */
    public MessageResponse reply(UUID userId, String slug, List<ImageData> images) {
        checkImages(images);
        var character = character(slug);
        var conversation = conversation(userId, character);
        var recent = messageRepository.findTop30ByConversationIdOrderBySentAtDesc(conversation.getId()).reversed();
        if (recent.isEmpty() || recent.getLast().getSender() == Message.Sender.friend) {
            throw new DomainException(DomainException.Kind.CONFLICT, "nothing_to_answer",
                    "Your friend already answered.");
        }
        var imageRefs = imageRefs(recent);
        var latest = recent.getLast();
        var turns = recent.stream()
                .map(message -> message == latest && !images.isEmpty()
                        ? new GeminiClient.Turn(true, turnText(message, 0), images)
                        : new GeminiClient.Turn(message.getSender() == Message.Sender.user,
                                turnText(message, imageRefs.getOrDefault(message.getId(), List.of()).size())))
                .toList();
        var answer = geminiClient.generate(SHARED_RULES + CHAT_RULES + CHARACTER_HEADING + character.getPersona(),
                turns);
        return toResponse(messageRepository.save(
                new Message(conversation.getId(), Message.Sender.friend, answer, null)), List.of());
    }

    /**
     * Everything the app needs to call this friend through the shared ElevenLabs agent. Not transactional: the
     * token request goes to ElevenLabs and must not hold a database connection.
     */
    public CallPassResponse callPass(UUID userId, String slug) {
        var character = character(slug);
        conversation(userId, character);
        if (character.getElevenlabsVoiceId() == null) {
            throw new DomainException(DomainException.Kind.UNAVAILABLE, "call_unavailable",
                    "Calls with this friend aren't set up yet.");
        }
        return new CallPassResponse(elevenLabsClient.conversationToken(),
                SHARED_RULES + CALL_RULES + CHARACTER_HEADING + character.getPersona(),
                "Hey, it's %s!".formatted(character.getName()), character.getElevenlabsVoiceId());
    }

    /** Saves the record of a finished call, as your message. */
    @Transactional
    public MessageResponse saveCall(UUID userId, String slug, CallRecordRequest request) {
        var conversation = conversation(userId, character(slug));
        return toResponse(messageRepository.save(
                Message.callRecord(conversation.getId(), request.durationSeconds())), List.of());
    }

    private static void checkImages(List<ImageData> images) {
        var invalid = images.size() > MAX_IMAGES || images.stream()
                .anyMatch(image -> !IMAGE_TYPES.contains(image.mimeType()) || image.bytes().length > MAX_IMAGE_BYTES);
        if (invalid) {
            throw new DomainException(DomainException.Kind.INVALID, "invalid_image",
                    "Send up to 4 JPEG, PNG, WebP or HEIC photos of 5 MB or less.");
        }
    }

    /** The message as Gemini reads it, noting a call, a post reply and photos it can't see. */
    private static String turnText(Message message, int unseenPhotos) {
        if (message.getCallDurationSeconds() instanceof Integer seconds) {
            return "(we had a voice call, %d:%02d)".formatted(seconds / 60, seconds % 60);
        }
        var text = message.getBody();
        if (unseenPhotos > 0) {
            text = "(shared %d photo%s) ".formatted(unseenPhotos, unseenPhotos == 1 ? "" : "s") + text;
        }
        if (message.getPostRef() != null) {
            text = POST_REPLY_PREFIX + text;
        }
        return text.trim();
    }

    private Map<UUID, List<String>> imageRefs(List<Message> messages) {
        return messageImageRepository.findByMessageIdInOrderByPosition(
                        messages.stream().map(Message::getId).toList()).stream()
                .collect(Collectors.groupingBy(MessageImage::getMessageId,
                        Collectors.mapping(MessageImage::getDeviceRef, Collectors.toList())));
    }

    private AiCharacter character(String slug) {
        return aiCharacterRepository.findBySlug(slug).orElseThrow(ChatService::chatNotFound);
    }

    /** Another user's chat looks exactly like one that doesn't exist. */
    private Conversation conversation(UUID userId, AiCharacter character) {
        return conversationRepository.findByUserIdAndCharacterId(userId, character.getId())
                .orElseThrow(ChatService::chatNotFound);
    }

    private ChatResponse summary(Conversation conversation, AiCharacter character) {
        var last = messageRepository.findFirstByConversationIdOrderBySentAtDesc(conversation.getId()).orElseThrow();
        var unread = conversation.getLastReadAt() == null
                ? messageRepository.countByConversationIdAndSender(conversation.getId(), Message.Sender.friend)
                : messageRepository.countByConversationIdAndSenderAndSentAtAfter(conversation.getId(),
                        Message.Sender.friend, conversation.getLastReadAt());
        return new ChatResponse(character.getSlug(), character.getName(), character.getVoiceLabel(),
                toResponse(last, imageRefs(List.of(last)).getOrDefault(last.getId(), List.of())), unread);
    }

    private static MessageResponse toResponse(Message message, List<String> imageRefs) {
        return new MessageResponse(message.getId(), message.getBody(), message.getSentAt(),
                message.getSender() == Message.Sender.user, message.getPostRef(), imageRefs,
                message.getCallDurationSeconds());
    }

    private static DomainException chatNotFound() {
        return new DomainException(DomainException.Kind.NOT_FOUND, "chat_not_found", "That chat doesn't exist.");
    }
}
