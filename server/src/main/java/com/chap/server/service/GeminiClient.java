package com.chap.server.service;

import com.chap.server.dto.ImageData;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/** Gemini's generateContent over plain HTTP. The key never leaves the server. */
@Component
public class GeminiClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiClient.class);
    private static final Duration TIMEOUT = Duration.ofSeconds(30);

    /** One message in the conversation sent to Gemini, with the photos Gemini should look at. */
    public record Turn(boolean fromUser, String text, List<ImageData> images) {

        public Turn(boolean fromUser, String text) {
            this(fromUser, text, List.of());
        }
    }

    // The response, as far as it's read.
    private record Part(String text) {
    }

    private record Content(String role, List<Part> parts) {
    }

    private record Candidate(Content content) {
    }

    private record GenerateResponse(List<Candidate> candidates) {
    }

    private final RestClient restClient;
    private final String apiKey;
    private final String model;

    public GeminiClient(@Value("${chap.gemini.api-key}") String apiKey, @Value("${chap.gemini.model}") String model,
            @Value("${chap.gemini.base-url:https://generativelanguage.googleapis.com/v1beta}") String baseUrl) {
        var requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(TIMEOUT);
        requestFactory.setReadTimeout(TIMEOUT);
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(requestFactory).build();
        this.apiKey = apiKey;
        this.model = model;
    }

    /** The model's answer to the conversation, in the role described by {@code instructions}. */
    public String generate(String instructions, List<Turn> conversation) {
        if (apiKey.isBlank()) {
            throw new DomainException(DomainException.Kind.UNAVAILABLE, "ai_unavailable",
                    "Replies aren't set up on the server yet.");
        }
        var request = Map.of(
                "systemInstruction", Map.of("parts", List.of(Map.of("text", instructions))),
                "contents", conversation.stream().map(GeminiClient::content).toList());
        GenerateResponse response;
        try {
            response = restClient.post()
                    .uri("/models/{model}:generateContent", model)
                    .header("x-goog-api-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(GenerateResponse.class);
        } catch (RestClientException ex) {
            log.warn("Gemini request failed: {}", ex.getMessage());
            throw failed();
        }
        // No candidates or no text means Gemini blocked or dropped the answer.
        var text = response == null || response.candidates() == null ? "" : response.candidates().stream()
                .findFirst()
                .map(Candidate::content)
                .filter(content -> content.parts() != null)
                .map(content -> content.parts().stream()
                        .map(Part::text)
                        .filter(Objects::nonNull)
                        .collect(Collectors.joining()))
                .orElse("");
        if (text.isBlank()) {
            throw failed();
        }
        return text.trim();
    }

    /** Photos go first as inline data, then the text. */
    private static Map<String, Object> content(Turn turn) {
        var parts = new ArrayList<Map<String, Object>>();
        for (var image : turn.images()) {
            parts.add(Map.of("inlineData", Map.of(
                    "mimeType", image.mimeType(),
                    "data", Base64.getEncoder().encodeToString(image.bytes()))));
        }
        if (!turn.text().isBlank()) {
            parts.add(Map.of("text", turn.text()));
        }
        return Map.of("role", turn.fromUser() ? "user" : "model", "parts", parts);
    }

    private static DomainException failed() {
        return new DomainException(DomainException.Kind.UPSTREAM_FAILED, "ai_failed",
                "Your friend couldn't answer. Try again.");
    }
}
