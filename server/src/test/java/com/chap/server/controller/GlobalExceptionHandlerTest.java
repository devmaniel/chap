package com.chap.server.controller;

import static org.assertj.core.api.Assertions.assertThat;

import com.chap.server.service.DomainException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

class GlobalExceptionHandlerTest {

    // Standalone: no application context. Spring Boot test scanning also skips classes nested in tests.
    private final MockMvcTester mvc = MockMvcTester.create(MockMvcBuilders
            .standaloneSetup(new ProbeController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .build());

    @Test
    void invalidBodyIsInvalidRequest() {
        assertThat(mvc.post().uri("/probe").contentType(MediaType.APPLICATION_JSON).content("{\"name\":\" \"}"))
                .hasStatus(400)
                .bodyJson().extractingPath("$.code").isEqualTo("invalid_request");
    }

    @Test
    void malformedJsonIsInvalidRequest() {
        assertThat(mvc.post().uri("/probe").contentType(MediaType.APPLICATION_JSON).content("{"))
                .hasStatus(400)
                .bodyJson().extractingPath("$.code").isEqualTo("invalid_request");
    }

    @Test
    void domainExceptionKeepsItsCode() {
        assertThat(mvc.get().uri("/probe/conflict"))
                .hasStatus(409)
                .bodyJson().extractingPath("$.code").isEqualTo("email_taken");
    }

    @Test
    void oversizedUploadIsInvalidImage() {
        assertThat(mvc.get().uri("/probe/huge-upload"))
                .hasStatus(400)
                .bodyJson().extractingPath("$.code").isEqualTo("invalid_image");
    }

    @Test
    void unexpectedFailureHidesDetails() {
        assertThat(mvc.get().uri("/probe/boom"))
                .hasStatus(500)
                .bodyText().contains("internal_error").doesNotContain("secret detail");
    }

    @RestController
    static class ProbeController {

        record Body(@NotBlank String name) {
        }

        @PostMapping("/probe")
        void valid(@Valid @RequestBody Body body) {
        }

        @GetMapping("/probe/conflict")
        void conflict() {
            throw new DomainException(DomainException.Kind.CONFLICT, "email_taken", "That email is taken.");
        }

        @GetMapping("/probe/huge-upload")
        void hugeUpload() {
            throw new MaxUploadSizeExceededException(10 * 1024 * 1024);
        }

        @GetMapping("/probe/boom")
        void boom() {
            throw new IllegalStateException("secret detail");
        }
    }
}
