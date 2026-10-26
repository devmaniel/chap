package com.chap.server.controller;

import static org.assertj.core.api.Assertions.assertThat;

import com.chap.server.TestcontainersConfiguration;
import com.chap.server.service.TokenService;
import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class AuthControllerTest {

    @Autowired
    MockMvcTester mvc;

    @Autowired
    TokenService tokenService;

    @Test
    void signUpStoresTheEmailLowercaseAndSignsIn() throws Exception {
        var id = UUID.randomUUID();

        var result = signUp("Melco", "Melco-" + id + "@Example.com", "otterly42");

        assertThat(result).hasStatus(201);
        assertThat(result).bodyJson().extractingPath("$.user.name").isEqualTo("Melco");
        assertThat(result).bodyJson().extractingPath("$.user.email").isEqualTo("melco-" + id + "@example.com");
        assertThat(me(tokenOf(result))).hasStatusOk()
                .bodyJson().extractingPath("$.email").isEqualTo("melco-" + id + "@example.com");
    }

    @Test
    void emailIsTakenInAnyLetterCase() {
        var email = uniqueEmail();
        signUp("Jamie", email, "otterly42");

        assertThat(signUp("Other", email.toUpperCase(), "whatever1"))
                .hasStatus(409)
                .bodyJson().extractingPath("$.code").isEqualTo("email_taken");
    }

    @Test
    void shortPasswordCreatesNoAccount() {
        var email = uniqueEmail();

        assertThat(signUp("Jamie", email, "1234567"))
                .hasStatus(400)
                .bodyJson().extractingPath("$.code").isEqualTo("invalid_request");
        assertThat(signUp("Jamie", email, "12345678")).hasStatus(201);
    }

    @Test
    void signInWithTheRightPasswordStartsASession() throws Exception {
        var email = uniqueEmail();
        signUp("Jamie", email, "otterly42");

        var result = signIn(email.toUpperCase(), "otterly42");

        assertThat(result).hasStatusOk();
        assertThat(me(tokenOf(result))).hasStatusOk();
    }

    @Test
    void wrongPasswordAndUnknownEmailFailTheSameWay() {
        var email = uniqueEmail();
        signUp("Jamie", email, "otterly42");

        for (var result : new MvcTestResult[] {signIn(email, "otterly43"), signIn(uniqueEmail(), "otterly42")}) {
            assertThat(result).hasStatus(401).bodyJson().isLenientlyEqualTo("""
                    {"code": "wrong_credentials", "message": "Email or password is wrong."}
                    """);
        }
    }

    @Test
    void meNeedsAValidSession() {
        assertThat(mvc.get().uri("/api/me"))
                .hasStatus(401)
                .bodyJson().extractingPath("$.code").isEqualTo("unauthorized");
        assertThat(me("not-a-token"))
                .hasStatus(401)
                .bodyJson().extractingPath("$.code").isEqualTo("unauthorized");
        // Signed correctly, but the account is gone (e.g. the database was reset).
        assertThat(me(tokenService.issue(UUID.randomUUID())))
                .hasStatus(401)
                .bodyJson().extractingPath("$.code").isEqualTo("unauthorized");
    }

    private MvcTestResult signUp(String name, String email, String password) {
        return post("/api/auth/sign-up", """
                {"name": "%s", "email": "%s", "password": "%s"}
                """.formatted(name, email, password));
    }

    private MvcTestResult signIn(String email, String password) {
        return post("/api/auth/sign-in", """
                {"email": "%s", "password": "%s"}
                """.formatted(email, password));
    }

    private MvcTestResult post(String uri, String json) {
        return mvc.post().uri(uri).contentType(MediaType.APPLICATION_JSON).content(json).exchange();
    }

    private MvcTestResult me(String token) {
        return mvc.get().uri("/api/me").header("Authorization", "Bearer " + token).exchange();
    }

    private static String tokenOf(MvcTestResult result) throws Exception {
        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }

    private static String uniqueEmail() {
        return "user-" + UUID.randomUUID() + "@example.com";
    }
}
