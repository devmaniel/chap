package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Entity
@Table(name = "conversations")
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID userId;

    private UUID characterId;

    private Instant lastReadAt;

    protected Conversation() {
    }

    public Conversation(UUID userId, UUID characterId) {
        this.userId = userId;
        this.characterId = characterId;
    }

    public UUID getId() {
        return id;
    }

    public UUID getCharacterId() {
        return characterId;
    }

    /** Null until the user first opens the chat. */
    public Instant getLastReadAt() {
        return lastReadAt;
    }

    public void markRead() {
        lastReadAt = Instant.now().truncatedTo(ChronoUnit.MICROS);
    }
}
