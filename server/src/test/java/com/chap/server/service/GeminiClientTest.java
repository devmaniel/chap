package com.chap.server.service;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.chap.server.dto.ImageData;
import com.jayway.jsonpath.JsonPath;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Runs against a fake Gemini on localhost. */
class GeminiClientTest {

    private static final List<GeminiClient.Turn> CONVERSATION = List.of(
            new GeminiClient.Turn(false, "Saved you a plate."),
            new GeminiClient.Turn(true, "Coming!"));

    HttpServer server;
    int status;
    String responseBody;
    String requestPath;
    String requestKey;
    String requestBody;

    @BeforeEach
    void startFakeGemini() throws IOException {
        server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        server.createContext("/", exchange -> {
            requestPath = exchange.getRequestURI().getPath();
            requestKey = exchange.getRequestHeaders().getFirst("x-goog-api-key");
            requestBody = new String(exchange.getRequestBody().readAllBytes(), UTF_8);
            var bytes = responseBody.getBytes(UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(status, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();
    }

    @AfterEach
    void stopFakeGemini() {
        server.stop(0);
    }

    GeminiClient client(String apiKey) {
        return new GeminiClient(apiKey, "gemini-test", "http://localhost:" + server.getAddress().getPort());
    }

    @Test
    void sendsInstructionsAndConversationAndReturnsTheText() {
        status = 200;
        responseBody = """
                {"candidates": [{"content": {"role": "model", "parts": [{"text": "Great, "}, {"text": "see you! "}]},
                                 "finishReason": "STOP"}]}
                """;

        var answer = client("secret").generate("You are Bo.", CONVERSATION);

        assertThat(answer).isEqualTo("Great, see you!");
        assertThat(requestPath).isEqualTo("/models/gemini-test:generateContent");
        assertThat(requestKey).isEqualTo("secret");
        assertThat(JsonPath.<String>read(requestBody, "$.systemInstruction.parts[0].text")).isEqualTo("You are Bo.");
        assertThat(JsonPath.<List<String>>read(requestBody, "$.contents[*].role")).containsExactly("model", "user");
        assertThat(JsonPath.<List<String>>read(requestBody, "$.contents[*].parts[0].text"))
                .containsExactly("Saved you a plate.", "Coming!");
    }

    @Test
    void sendsPhotosAsInlineDataBeforeTheText() {
        status = 200;
        responseBody = """
                {"candidates": [{"content": {"parts": [{"text": "Red!"}]}}]}
                """;
        var photo = new ImageData("image/jpeg", new byte[] {1, 2, 3});

        client("secret").generate("You are Momo.", List.of(new GeminiClient.Turn(true, "What color?", List.of(photo))));

        assertThat(JsonPath.<Map<String, Object>>read(requestBody, "$.contents[0].parts[0].inlineData"))
                .containsEntry("mimeType", "image/jpeg")
                .containsEntry("data", Base64.getEncoder().encodeToString(new byte[] {1, 2, 3}));
        assertThat(JsonPath.<String>read(requestBody, "$.contents[0].parts[1].text")).isEqualTo("What color?");
    }

    @Test
    void withoutAKeyRepliesAreUnavailable() {
        assertThatThrownBy(() -> client("").generate("You are Bo.", CONVERSATION))
                .isInstanceOfSatisfying(DomainException.class, ex -> {
                    assertThat(ex.kind()).isEqualTo(DomainException.Kind.UNAVAILABLE);
                    assertThat(ex.code()).isEqualTo("ai_unavailable");
                });
        assertThat(requestPath).isNull();
    }

    @Test
    void errorsAndMissingAnswersFail() {
        var failures = List.of(
                new Object[] {500, "{\"error\": {\"message\": \"boom\"}}"},
                new Object[] {200, "{\"candidates\": []}"},
                new Object[] {200, "{\"promptFeedback\": {\"blockReason\": \"SAFETY\"}}"},
                new Object[] {200, "{\"candidates\": [{\"finishReason\": \"SAFETY\"}]}"});
        for (var failure : failures) {
            status = (int) failure[0];
            responseBody = (String) failure[1];

            assertThatThrownBy(() -> client("secret").generate("You are Bo.", CONVERSATION))
                    .as(responseBody)
                    .isInstanceOfSatisfying(DomainException.class, ex -> {
                        assertThat(ex.kind()).isEqualTo(DomainException.Kind.UPSTREAM_FAILED);
                        assertThat(ex.code()).isEqualTo("ai_failed");
                    });
        }
    }
}
