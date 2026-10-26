package com.chap.server.dto;

/** A chat as the inbox shows it. {@code id} is the friend's slug. */
public record ChatResponse(String id, String friendName, String friendVoice, MessageResponse lastMessage,
        long unreadCount) {
}
