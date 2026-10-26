package com.chap.server.dto;

/** A photo sent with a reply request. Passed to Gemini, never stored. */
public record ImageData(String mimeType, byte[] bytes) {
}
