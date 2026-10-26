package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "user_friends")
@IdClass(UserFriend.Key.class)
public class UserFriend {

    public record Key(UUID userId, UUID characterId) implements Serializable {
    }

    @Id
    private UUID userId;

    @Id
    private UUID characterId;

    protected UserFriend() {
    }

    public UserFriend(UUID userId, UUID characterId) {
        this.userId = userId;
        this.characterId = characterId;
    }

    public UUID getCharacterId() {
        return characterId;
    }
}
