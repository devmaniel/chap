package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Entity
@Table(name = "messages")
public class Message {

    /** Lowercase to match the column's CHECK constraint. */
    public enum Sender { user, friend }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID conversationId;

    @Enumerated(EnumType.STRING)
    private Sender sender;

    private String body;

    private String postRef;

    private Instant sentAt;

    /** Set only on a call record. */
    private Integer callDurationSeconds;

    protected Message() {
    }

    /** The record of a voice call you made, with an empty body. */
    public static Message callRecord(UUID conversationId, int durationSeconds) {
        var message = new Message(conversationId, Sender.user, "", null);
        message.callDurationSeconds = durationSeconds;
        return message;
    }

    public Message(UUID conversationId, Sender sender, String body, String postRef) {
        this.conversationId = conversationId;
        this.sender = sender;
        this.body = body;
        this.postRef = postRef;
        // Microseconds: what Postgres stores, so the saved value and the returned one match.
        this.sentAt = Instant.now().truncatedTo(ChronoUnit.MICROS);
    }

    public UUID getId() {
        return id;
    }

    public Sender getSender() {
        return sender;
    }

    public String getBody() {
        return body;
    }

    public String getPostRef() {
        return postRef;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public Integer getCallDurationSeconds() {
        return callDurationSeconds;
    }
}
