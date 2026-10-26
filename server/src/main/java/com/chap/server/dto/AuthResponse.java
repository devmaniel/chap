package com.chap.server.dto;

/** A new session: the token the app sends as {@code Authorization: Bearer}, and who it belongs to. */
public record AuthResponse(String token, UserResponse user) {
}
