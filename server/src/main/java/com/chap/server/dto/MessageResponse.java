package com.chap.server.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * {@code postId} is the app-side post the message replies to, if any. {@code imageRefs} are the phone's own
 * references to the photos in it, in order. {@code callDurationSeconds} is set only on a call record.
 */
public record MessageResponse(UUID id, String text, Instant sentAt, boolean isFromYou, String postId,
        List<String> imageRefs, Integer callDurationSeconds) {
}
