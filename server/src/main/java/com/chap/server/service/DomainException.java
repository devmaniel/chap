package com.chap.server.service;

/**
 * A business failure the client should see. {@code code} is the stable,
 * snake_case value the app switches on, e.g. {@code email_taken}.
 */
public class DomainException extends RuntimeException {

    public enum Kind { INVALID, UNAUTHORIZED, NOT_FOUND, CONFLICT, UPSTREAM_FAILED, UNAVAILABLE }

    private final Kind kind;
    private final String code;

    public DomainException(Kind kind, String code, String message) {
        super(message);
        this.kind = kind;
        this.code = code;
    }

    public Kind kind() {
        return kind;
    }

    public String code() {
        return code;
    }
}
