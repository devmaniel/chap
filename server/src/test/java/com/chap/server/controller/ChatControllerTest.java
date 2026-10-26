package com.chap.server.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.chap.server.TestcontainersConfiguration;
import com.chap.server.service.DomainException;
import com.chap.server.service.ElevenLabsClient;
import com.chap.server.service.GeminiClient;
import com.jayway.jsonpath.JsonPath;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class ChatControllerTest {

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    GeminiClient geminiClient;

    @MockitoBean
    ElevenLabsClient elevenLabsClient;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void startingOpensWithTheHelloAndCanBeRepeated() throws Exception {
        var token = signUp();

        assertThat(call(token, "PUT", "/api/chats/vera")).hasStatusOk();
        var again = call(token, "PUT", "/api/chats/vera");

        assertThat(again).hasStatusOk().bodyJson().isLenientlyEqualTo("""
                {"id": "vera", "friendName": "Vera", "friendVoice": "Sharp & direct", "unreadCount": 1,
                 "lastMessage": {"isFromYou": false,
                   "text": "Interviewed twenty people this week. Hired two. Bring your best answer."}}
                """);
        assertThat(messages(token, "vera")).hasSize(1);
    }

    @Test
    void unknownFriendCannotBeStarted() throws Exception {
        assertThat(call(signUp(), "PUT", "/api/chats/nobody"))
                .hasStatus(404)
                .bodyJson().extractingPath("$.code").isEqualTo("character_not_found");
    }

    @Test
    void inboxIsNewestFirstWithUnreadCounts() throws Exception {
        var token = signUp();
        assertThat(inbox(token)).isEmpty();
        call(token, "PUT", "/api/chats/mina");
        call(token, "PUT", "/api/chats/bo");

        assertThat(inbox(token)).extracting(chat -> chat.get(0)).containsExactly("bo", "mina");

        send(token, "mina", "Hi Mina");
        when(geminiClient.generate(anyString(), any())).thenReturn("Hey you!");
        call(token, "POST", "/api/chats/mina/reply");

        var inbox = inbox(token);
        assertThat(inbox.getFirst()).containsExactly("mina", "Hey you!", "2");
        assertThat(inbox.getLast()).containsExactly("bo", "Saved you a plate. Coming by tonight?", "1");
    }

    @Test
    void openingAChatMarksItRead() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/pip");

        assertThat(call(token, "POST", "/api/chats/pip/read")).hasStatus(204);

        assertThat(call(token, "GET", "/api/chats/pip")).bodyJson().extractingPath("$.unreadCount").isEqualTo(0);
    }

    @Test
    void sendRejectsBlankAndTooLongText() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/momo");

        assertThat(send(token, "momo", "How was your day?")).hasStatus(201)
                .bodyJson().isLenientlyEqualTo("""
                        {"text": "How was your day?", "isFromYou": true, "postId": null}
                        """);
        for (var text : new String[] {"   ", "x".repeat(2001)}) {
            assertThat(send(token, "momo", text))
                    .hasStatus(400)
                    .bodyJson().extractingPath("$.code").isEqualTo("invalid_request");
        }
        assertThat(messages(token, "momo")).hasSize(2);
    }

    @Test
    void aPostReplyMayHaveNoText() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/mina");

        var result = post(token, "/api/chats/mina/messages", """
                {"text": "", "postId": "mina-1"}
                """);

        assertThat(result).hasStatus(201).bodyJson().extractingPath("$.postId").isEqualTo("mina-1");
    }

    @Test
    void replyIsSavedAndSentWithPersonaAndHistory() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/vera");
        send(token, "vera", "I have an interview tomorrow");
        when(geminiClient.generate(anyString(), any())).thenReturn("Good. What's your weakest answer?");

        var result = call(token, "POST", "/api/chats/vera/reply");

        assertThat(result).hasStatusOk().bodyJson().isLenientlyEqualTo("""
                {"text": "Good. What's your weakest answer?", "isFromYou": false}
                """);
        assertThat(messages(token, "vera")).hasSize(3);
        ArgumentCaptor<String> instructions = ArgumentCaptor.captor();
        ArgumentCaptor<List<GeminiClient.Turn>> turns = ArgumentCaptor.captor();
        verify(geminiClient).generate(instructions.capture(), turns.capture());
        assertThat(instructions.getValue())
                .contains("Never claim to be human")
                .contains("You are Vera");
        assertThat(turns.getValue()).containsExactly(
                new GeminiClient.Turn(false,
                        "Interviewed twenty people this week. Hired two. Bring your best answer."),
                new GeminiClient.Turn(true, "I have an interview tomorrow"));
    }

    @Test
    void aPostReplyIsMarkedForGemini() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/mina");
        post(token, "/api/chats/mina/messages", """
                {"text": "Love this", "postId": "mina-1"}
                """);
        when(geminiClient.generate(anyString(), any())).thenReturn("Thanks!");

        call(token, "POST", "/api/chats/mina/reply");

        ArgumentCaptor<List<GeminiClient.Turn>> turns = ArgumentCaptor.captor();
        verify(geminiClient).generate(anyString(), turns.capture());
        assertThat(turns.getValue().getLast().text()).isEqualTo("(replying to your post) Love this");
    }

    @Test
    void nothingToAnswerWhenTheFriendSpokeLast() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/bo");

        assertThat(call(token, "POST", "/api/chats/bo/reply"))
                .hasStatus(409)
                .bodyJson().extractingPath("$.code").isEqualTo("nothing_to_answer");
    }

    @Test
    void aFailedReplySavesNothingAndCanBeRetried() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/ziggy");
        send(token, "ziggy", "Any news?");
        when(geminiClient.generate(anyString(), any()))
                .thenThrow(new DomainException(DomainException.Kind.UNAVAILABLE, "ai_unavailable", "Not set up."))
                .thenThrow(new DomainException(DomainException.Kind.UPSTREAM_FAILED, "ai_failed", "Failed."))
                .thenReturn("Okay so...");

        assertThat(call(token, "POST", "/api/chats/ziggy/reply"))
                .hasStatus(503).bodyJson().extractingPath("$.code").isEqualTo("ai_unavailable");
        assertThat(call(token, "POST", "/api/chats/ziggy/reply"))
                .hasStatus(502).bodyJson().extractingPath("$.code").isEqualTo("ai_failed");
        assertThat(messages(token, "ziggy")).hasSize(2);

        assertThat(call(token, "POST", "/api/chats/ziggy/reply")).hasStatusOk();
        assertThat(messages(token, "ziggy")).hasSize(3);
    }

    @Test
    void anotherUsersChatIsNotFound() throws Exception {
        var owner = signUp();
        var other = signUp();
        call(owner, "PUT", "/api/chats/mina");

        for (var path : new String[] {"/api/chats/mina", "/api/chats/mina/messages"}) {
            assertThat(call(other, "GET", path))
                    .hasStatus(404)
                    .bodyJson().extractingPath("$.code").isEqualTo("chat_not_found");
        }
        assertThat(send(other, "mina", "hi")).hasStatus(404);
        assertThat(inbox(other)).isEmpty();
    }

    @Test
    void aMessageCanBeJustPhotos() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/momo");

        var result = post(token, "/api/chats/momo/messages", """
                {"text": "", "imageRefs": ["/phone/a.jpg", "/phone/b.jpg"]}
                """);

        assertThat(result).hasStatus(201)
                .bodyJson().extractingPath("$.imageRefs").asArray().containsExactly("/phone/a.jpg", "/phone/b.jpg");
        assertThat(call(token, "GET", "/api/chats/momo/messages"))
                .bodyJson().extractingPath("$[1].imageRefs").asArray().containsExactly("/phone/a.jpg", "/phone/b.jpg");
        assertThat(call(token, "GET", "/api/chats"))
                .bodyJson().extractingPath("$[0].lastMessage.imageRefs").asArray().hasSize(2);
    }

    @Test
    void fivePhotosAreTooMany() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/momo");

        assertThat(post(token, "/api/chats/momo/messages", """
                {"text": "", "imageRefs": ["1", "2", "3", "4", "5"]}
                """))
                .hasStatus(400)
                .bodyJson().extractingPath("$.code").isEqualTo("invalid_request");
        assertThat(messages(token, "momo")).hasSize(1);
    }

    @Test
    void replyPhotosReachGeminiAndAreNotStored() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/momo");
        post(token, "/api/chats/momo/messages", """
                {"text": "What color is it?", "imageRefs": ["/phone/bike.jpg"]}
                """);
        when(geminiClient.generate(anyString(), any())).thenReturn("Red. Very red.");
        var photo = new byte[] {1, 2, 3};

        var result = mvc.post().uri("/api/chats/momo/reply").multipart()
                .file(new MockMultipartFile("images", "bike.jpg", "image/jpeg", photo))
                .header("Authorization", "Bearer " + token)
                .exchange();

        assertThat(result).hasStatusOk().bodyJson().isLenientlyEqualTo("""
                {"text": "Red. Very red.", "imageRefs": []}
                """);
        ArgumentCaptor<List<GeminiClient.Turn>> turns = ArgumentCaptor.captor();
        verify(geminiClient).generate(anyString(), turns.capture());
        var latest = turns.getValue().getLast();
        assertThat(latest.text()).isEqualTo("What color is it?");
        assertThat(latest.images()).singleElement().satisfies(image -> {
            assertThat(image.mimeType()).isEqualTo("image/jpeg");
            assertThat(image.bytes()).isEqualTo(photo);
        });
        // Only the phone reference is kept; the reply itself has no photo rows.
        assertThat(jdbc.queryForList("""
                SELECT i.device_ref FROM message_images i
                JOIN messages m ON m.id = i.message_id
                JOIN conversations c ON c.id = m.conversation_id
                WHERE c.id = (SELECT conversation_id FROM messages WHERE body = 'Red. Very red.')
                """, String.class)).containsExactly("/phone/bike.jpg");
    }

    @Test
    void olderPhotosReachGeminiAsText() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/bo");
        post(token, "/api/chats/bo/messages", """
                {"text": "Dinner!", "imageRefs": ["/phone/1.jpg", "/phone/2.jpg"]}
                """);
        when(geminiClient.generate(anyString(), any())).thenReturn("Looks great.");

        call(token, "POST", "/api/chats/bo/reply");

        ArgumentCaptor<List<GeminiClient.Turn>> turns = ArgumentCaptor.captor();
        verify(geminiClient).generate(anyString(), turns.capture());
        assertThat(turns.getValue().getLast()).isEqualTo(new GeminiClient.Turn(true, "(shared 2 photos) Dinner!"));
    }

    @Test
    void badReplyPhotosAreRejectedAndNothingIsSaved() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/pip");
        send(token, "pip", "Look");
        var tooBig = new byte[5 * 1024 * 1024 + 1];

        for (var file : new MockMultipartFile[] {
                new MockMultipartFile("images", "notes.pdf", "application/pdf", new byte[] {1}),
                new MockMultipartFile("images", "huge.jpg", "image/jpeg", tooBig)}) {
            assertThat(mvc.post().uri("/api/chats/pip/reply").multipart().file(file)
                    .header("Authorization", "Bearer " + token).exchange())
                    .hasStatus(400)
                    .bodyJson().extractingPath("$.code").isEqualTo("invalid_image");
        }
        assertThat(messages(token, "pip")).hasSize(2);
        verify(geminiClient, never()).generate(anyString(), any());
    }

    @Test
    void aCallPassMakesTheSharedAgentThisFriend() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/ziggy");
        jdbc.update("UPDATE characters SET elevenlabs_voice_id = 'voice-ziggy' WHERE slug = 'ziggy'");
        when(elevenLabsClient.conversationToken()).thenReturn("call-token");

        var result = call(token, "POST", "/api/chats/ziggy/call");

        assertThat(result).hasStatusOk().bodyJson().isLenientlyEqualTo("""
                {"conversationToken": "call-token", "firstMessage": "Hey, it's Ziggy!", "voiceId": "voice-ziggy"}
                """);
        assertThat(result).bodyJson().extractingPath("$.prompt").asString()
                .contains("Never claim to be human")
                .contains("live voice call")
                .contains("You are Ziggy")
                .doesNotContain("text message");
    }

    @Test
    void callsAreUnavailableUntilSetUp() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/bo");
        call(token, "PUT", "/api/chats/ziggy");
        jdbc.update("UPDATE characters SET elevenlabs_voice_id = NULL WHERE slug = 'bo'");
        when(elevenLabsClient.conversationToken())
                .thenThrow(new DomainException(DomainException.Kind.UNAVAILABLE, "call_unavailable", "Not set up."))
                .thenThrow(new DomainException(DomainException.Kind.UPSTREAM_FAILED, "call_failed", "Failed."));

        // Bo has no voice.
        assertThat(call(token, "POST", "/api/chats/bo/call"))
                .hasStatus(503).bodyJson().extractingPath("$.code").isEqualTo("call_unavailable");
        assertThat(call(token, "POST", "/api/chats/ziggy/call"))
                .hasStatus(503).bodyJson().extractingPath("$.code").isEqualTo("call_unavailable");
        assertThat(call(token, "POST", "/api/chats/ziggy/call"))
                .hasStatus(502).bodyJson().extractingPath("$.code").isEqualTo("call_failed");
    }

    @Test
    void aFinishedCallIsRecordedInTheChat() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/vera");

        var result = post(token, "/api/chats/vera/calls", """
                {"durationSeconds": 151}
                """);

        assertThat(result).hasStatus(201).bodyJson().isLenientlyEqualTo("""
                {"text": "", "isFromYou": true, "callDurationSeconds": 151, "imageRefs": []}
                """);
        assertThat(call(token, "GET", "/api/chats/vera"))
                .bodyJson().extractingPath("$.lastMessage.callDurationSeconds").isEqualTo(151);
        assertThat(post(token, "/api/chats/vera/calls", """
                {"durationSeconds": -1}
                """)).hasStatus(400);
    }

    @Test
    void aCallReachesGeminiAsANote() throws Exception {
        var token = signUp();
        call(token, "PUT", "/api/chats/vera");
        post(token, "/api/chats/vera/calls", """
                {"durationSeconds": 151}
                """);
        when(geminiClient.generate(anyString(), any())).thenReturn("Good call.");

        call(token, "POST", "/api/chats/vera/reply");

        ArgumentCaptor<List<GeminiClient.Turn>> turns = ArgumentCaptor.captor();
        verify(geminiClient).generate(anyString(), turns.capture());
        assertThat(turns.getValue().getLast()).isEqualTo(new GeminiClient.Turn(true, "(we had a voice call, 2:31)"));
    }

    @Test
    void anotherUsersChatCannotBeCalled() throws Exception {
        var owner = signUp();
        var other = signUp();
        call(owner, "PUT", "/api/chats/ziggy");

        assertThat(call(other, "POST", "/api/chats/ziggy/call")).hasStatus(404);
        assertThat(post(other, "/api/chats/ziggy/calls", """
                {"durationSeconds": 10}
                """)).hasStatus(404);
    }

    private String signUp() throws Exception {
        var result = post(null, "/api/auth/sign-up", """
                {"name": "Jamie", "email": "user-%s@example.com", "password": "otterly42"}
                """.formatted(UUID.randomUUID()));
        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }

    private MvcTestResult call(String token, String method, String uri) {
        var request = switch (method) {
            case "GET" -> mvc.get();
            case "PUT" -> mvc.put();
            default -> mvc.post();
        };
        return request.uri(uri).header("Authorization", "Bearer " + token).exchange();
    }

    private MvcTestResult post(String token, String uri, String json) {
        var request = mvc.post().uri(uri).contentType(MediaType.APPLICATION_JSON).content(json);
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        return request.exchange();
    }

    private MvcTestResult send(String token, String slug, String text) {
        return post(token, "/api/chats/" + slug + "/messages", """
                {"text": "%s"}
                """.formatted(text));
    }

    private List<Object> messages(String token, String slug) throws Exception {
        return JsonPath.read(call(token, "GET", "/api/chats/" + slug + "/messages").getResponse()
                .getContentAsString(), "$");
    }

    /** Each chat as [id, last message text, unread count]. */
    private List<List<String>> inbox(String token) throws Exception {
        var body = call(token, "GET", "/api/chats").getResponse().getContentAsString();
        List<String> ids = JsonPath.read(body, "$[*].id");
        List<String> texts = JsonPath.read(body, "$[*].lastMessage.text");
        List<Integer> unread = JsonPath.read(body, "$[*].unreadCount");
        return IntStream.range(0, ids.size())
                .mapToObj(i -> List.of(ids.get(i), texts.get(i), String.valueOf(unread.get(i))))
                .toList();
    }
}
