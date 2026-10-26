package com.chap.server.service;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/** ElevenLabs Agents over plain HTTP. The key never leaves the server. */
@Component
public class ElevenLabsClient {

    private static final Logger log = LoggerFactory.getLogger(ElevenLabsClient.class);
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private record TokenResponse(String token) {
    }

    private final RestClient restClient;
    private final String apiKey;
    private final String agentId;

    public ElevenLabsClient(@Value("${chap.elevenlabs.api-key}") String apiKey,
            @Value("${chap.elevenlabs.agent-id}") String agentId,
            @Value("${chap.elevenlabs.base-url:https://api.elevenlabs.io}") String baseUrl) {
        var requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(TIMEOUT);
        requestFactory.setReadTimeout(TIMEOUT);
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(requestFactory).build();
        this.apiKey = apiKey;
        this.agentId = agentId;
    }

    /** A short-lived token that lets the app start one WebRTC call with the shared agent. */
    public String conversationToken() {
        if (apiKey.isBlank() || agentId.isBlank()) {
            throw new DomainException(DomainException.Kind.UNAVAILABLE, "call_unavailable",
                    "Calls aren't set up on the server yet.");
        }
        TokenResponse response;
        try {
            response = restClient.get()
                    .uri("/v1/convai/conversation/token?agent_id={agentId}", agentId)
                    .header("xi-api-key", apiKey)
                    .retrieve()
                    .body(TokenResponse.class);
        } catch (RestClientException ex) {
            log.warn("ElevenLabs token request failed: {}", ex.getMessage());
            throw failed();
        }
        if (response == null || response.token() == null || response.token().isBlank()) {
            throw failed();
        }
        return response.token();
    }

    private static DomainException failed() {
        return new DomainException(DomainException.Kind.UPSTREAM_FAILED, "call_failed",
                "The call couldn't connect. Try again.");
    }
}
