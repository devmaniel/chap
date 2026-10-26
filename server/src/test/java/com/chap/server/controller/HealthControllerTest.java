package com.chap.server.controller;

import static org.assertj.core.api.Assertions.assertThat;

import com.chap.server.TestcontainersConfiguration;
import com.chap.server.service.TokenService;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

// No AI keys: the whole context starting here is the "starts without keys" check.
@SpringBootTest(properties = {"chap.gemini.api-key=", "chap.elevenlabs.api-key=", "chap.elevenlabs.agent-id="})
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class HealthControllerTest {

    @Autowired
    MockMvcTester mvc;

    @Autowired
    TokenService tokenService;

    @Test
    void reportsOkWhenDatabaseIsUp() {
        assertThat(mvc.get().uri("/api/health"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.status").isEqualTo("ok");
    }

    @Test
    void unknownPathIsNotFound() {
        // Signed in, so the request gets past security to routing.
        assertThat(mvc.get().uri("/api/nope")
                .header("Authorization", "Bearer " + tokenService.issue(UUID.randomUUID())))
                .hasStatus(404)
                .bodyJson().extractingPath("$.code").isEqualTo("not_found");
    }
}
