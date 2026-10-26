package com.chap.server.service;

import com.chap.server.dto.CharacterResponse;
import com.chap.server.entity.AiCharacter;
import com.chap.server.entity.UserFriend;
import com.chap.server.repository.AiCharacterRepository;
import com.chap.server.repository.UserFriendRepository;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CharacterService {

    private final AiCharacterRepository aiCharacterRepository;
    private final UserFriendRepository userFriendRepository;

    public CharacterService(AiCharacterRepository aiCharacterRepository,
            UserFriendRepository userFriendRepository) {
        this.aiCharacterRepository = aiCharacterRepository;
        this.userFriendRepository = userFriendRepository;
    }

    /** Every character, each marked with whether it is this user's friend. */
    @Transactional(readOnly = true)
    public List<CharacterResponse> list(UUID userId) {
        var friendIds = userFriendRepository.findByUserId(userId).stream()
                .map(UserFriend::getCharacterId)
                .collect(Collectors.toSet());
        return aiCharacterRepository.findAll(Sort.by("name")).stream()
                .map(character -> toResponse(character, friendIds.contains(character.getId())))
                .toList();
    }

    /** Adding someone who is already a friend changes nothing. */
    @Transactional
    public void addFriend(UUID userId, String slug) {
        var key = new UserFriend.Key(userId, find(slug).getId());
        if (!userFriendRepository.existsById(key)) {
            userFriendRepository.save(new UserFriend(key.userId(), key.characterId()));
        }
    }

    /** Removing someone who isn't a friend changes nothing. Their chat stays. */
    @Transactional
    public void removeFriend(UUID userId, String slug) {
        userFriendRepository.deleteById(new UserFriend.Key(userId, find(slug).getId()));
    }

    private AiCharacter find(String slug) {
        return aiCharacterRepository.findBySlug(slug)
                .orElseThrow(() -> new DomainException(DomainException.Kind.NOT_FOUND, "character_not_found",
                        "That friend doesn't exist."));
    }

    private static CharacterResponse toResponse(AiCharacter character, boolean isFriend) {
        return new CharacterResponse(character.getSlug(), character.getName(), character.getTagline(),
                character.getBio(), character.getInterests(), character.getHome(), character.getVoiceLabel(),
                character.getFirstHello(), isFriend);
    }
}
