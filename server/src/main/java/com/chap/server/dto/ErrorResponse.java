package com.chap.server.dto;

/** Body of every failed request. */
public record ErrorResponse(String code, String message) {
}
