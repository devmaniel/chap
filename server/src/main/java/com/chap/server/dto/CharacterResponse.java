package com.chap.server.dto;

import java.util.List;

/** A character as the app shows it. {@code id} is the slug; the persona is never included. */
public record CharacterResponse(
        String id,
        String name,
        String tagline,
        String bio,
        List<String> interests,
        String home,
        String voice,
        String firstHello,
        boolean isFriend) {
}
