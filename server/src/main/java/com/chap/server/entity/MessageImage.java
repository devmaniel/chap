package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.UUID;

/** A photo in a message: a reference to a file on the user's phone, never the image itself. */
@Entity
@Table(name = "message_images")
@IdClass(MessageImage.Key.class)
public class MessageImage {

    public record Key(UUID messageId, short position) implements Serializable {
    }

    @Id
    private UUID messageId;

    @Id
    private short position;

    private String deviceRef;

    protected MessageImage() {
    }

    public MessageImage(UUID messageId, short position, String deviceRef) {
        this.messageId = messageId;
        this.position = position;
        this.deviceRef = deviceRef;
    }

    public UUID getMessageId() {
        return messageId;
    }

    public String getDeviceRef() {
        return deviceRef;
    }
}
