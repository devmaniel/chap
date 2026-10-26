package com.chap.server.controller;

import com.chap.server.dto.ErrorResponse;
import com.chap.server.service.DomainException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/** The one place errors become HTTP responses. Never leaks internals. */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(DomainException.class)
    ResponseEntity<ErrorResponse> domain(DomainException ex) {
        var status = switch (ex.kind()) {
            case INVALID -> HttpStatus.BAD_REQUEST;
            case UNAUTHORIZED -> HttpStatus.UNAUTHORIZED;
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case UPSTREAM_FAILED -> HttpStatus.BAD_GATEWAY;
            case UNAVAILABLE -> HttpStatus.SERVICE_UNAVAILABLE;
        };
        return ResponseEntity.status(status).body(new ErrorResponse(ex.code(), ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ErrorResponse> unexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("internal_error", "Something went wrong."));
    }

    /** A photo far over the 5 MB limit is stopped before ChatService sees it; answer as ChatService would. */
    @Override
    protected ResponseEntity<Object> handleMaxUploadSizeExceededException(
            MaxUploadSizeExceededException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        return ResponseEntity.badRequest().body(new ErrorResponse("invalid_image",
                "Send up to 4 JPEG, PNG, WebP or HEIC photos of 5 MB or less."));
    }

    /** Spring MVC's own failures (bad body, validation, unknown path) in our shape. */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, Object body, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        var error = status.value() == 404
                ? new ErrorResponse("not_found", "Not found.")
                : status.is4xxClientError()
                        ? new ErrorResponse("invalid_request", "Check the request and try again.")
                        : new ErrorResponse("internal_error", "Something went wrong.");
        return ResponseEntity.status(status).headers(headers).body(error);
    }
}
