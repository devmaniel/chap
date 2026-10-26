package com.chap.server.service;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Runs against a fake ElevenLabs on localhost. */
class ElevenLabsClientTest {

    HttpServer server;
    int status;
    String responseBody;
    String requestPath;
    String requestQuery;
    String requestKey;

    @BeforeEach
    void startFakeElevenLabs() throws IOException {
        server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        server.createContext("/", exchange -> {
            requestPath = exchange.getRequestURI().getPath();
            requestQuery = exchange.getRequestURI().getQuery();
            requestKey = exchange.getRequestHeaders().getFirst("xi-api-key");
            var bytes = responseBody.getBytes(UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(status, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();
    }

    @AfterEach
    void stopFakeElevenLabs() {
        server.stop(0);
    }

    ElevenLabsClient client(String apiKey, String agentId) {
        return new ElevenLabsClient(apiKey, agentId, "http://localhost:" + server.getAddress().getPort());
    }

    @Test
    void fetchesAConversationTokenForTheAgent() {
        status = 200;
        responseBody = "{\"token\": \"call-token\"}";

        var token = client("secret", "agent-1").conversationToken();

        assertThat(token).isEqualTo("call-token");
        assertThat(requestPath).isEqualTo("/v1/convai/conversation/token");
        assertThat(requestQuery).isEqualTo("agent_id=agent-1");
        assertThat(requestKey).isEqualTo("secret");
    }

    @Test
    void withoutAKeyOrAgentCallsAreUnavailable() {
        for (var client : new ElevenLabsClient[] {client("", "agent-1"), client("secret", "")}) {
            assertThatThrownBy(client::conversationToken)
                    .isInstanceOfSatisfying(DomainException.class, ex -> {
                        assertThat(ex.kind()).isEqualTo(DomainException.Kind.UNAVAILABLE);
                        assertThat(ex.code()).isEqualTo("call_unavailable");
                    });
        }
        assertThat(requestPath).isNull();
    }

    @Test
    void errorsAndMissingTokensFail() {
        for (var failure : new Object[][] {{401, "{\"detail\": \"bad key\"}"}, {200, "{}"}}) {
            status = (int) failure[0];
            responseBody = (String) failure[1];

            assertThatThrownBy(() -> client("secret", "agent-1").conversationToken())
                    .as(responseBody)
                    .isInstanceOfSatisfying(DomainException.class, ex -> {
                        assertThat(ex.kind()).isEqualTo(DomainException.Kind.UPSTREAM_FAILED);
                        assertThat(ex.code()).isEqualTo("call_failed");
                    });
        }
    }
}
