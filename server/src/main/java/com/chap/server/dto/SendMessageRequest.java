package com.chap.server.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** Text may be empty only when the message carries photos or replies to a post. {@code imageRefs} may be null. */
public record SendMessageRequest(@NotNull @Size(max = 2000) String text, String postId,
        @Size(max = 4) List<@NotNull String> imageRefs) {
}
