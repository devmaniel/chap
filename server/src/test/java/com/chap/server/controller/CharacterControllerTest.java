package com.chap.server.controller;

import static org.assertj.core.api.Assertions.assertThat;

import com.chap.server.TestcontainersConfiguration;
import com.jayway.jsonpath.JsonPath;
import java.util.List;
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
class CharacterControllerTest {

    @Autowired
    MockMvcTester mvc;

    @Test
    void listsTheSixFriendsWithoutTheirPersona() throws Exception {
        var result = characters(signUp());

        assertThat(result).hasStatusOk();
        assertThat(result).bodyJson().extractingPath("$[*].id")
                .asArray().containsExactly("bo", "mina", "momo", "pip", "vera", "ziggy");
        assertThat(result).bodyJson().extractingPath("$[?(@.id == 'mina')]").isEqualTo(JsonPath.parse("""
                [{"id": "mina", "name": "Mina",
                  "tagline": "Unemployed adventurer, always planning the next trip.",
                  "bio": "Unemployed adventurer. Just back from a trip to find himself, already planning the next one.",
                  "interests": ["Travel", "Food", "Stories"], "home": "On the road", "voice": "Bright & bold",
                  "firstHello": "I missed my bus, so I hitched a ride to the coast instead. Best mistake this week.",
                  "isFriend": false}]
                """).json());
        assertThat(result.getResponse().getContentAsString()).doesNotContain("persona", "You are");
    }

    @Test
    void addAndRemoveCanBeRepeated() throws Exception {
        var token = signUp();

        assertThat(friend(token, "PUT", "vera")).hasStatus(204);
        assertThat(friend(token, "PUT", "vera")).hasStatus(204);
        assertThat(isFriend(token, "vera")).isTrue();

        assertThat(friend(token, "DELETE", "vera")).hasStatus(204);
        assertThat(friend(token, "DELETE", "vera")).hasStatus(204);
        assertThat(isFriend(token, "vera")).isFalse();
    }

    @Test
    void unknownCharacterIsNotFound() throws Exception {
        var token = signUp();

        for (var method : new String[] {"PUT", "DELETE"}) {
            assertThat(friend(token, method, "nobody"))
                    .hasStatus(404)
                    .bodyJson().extractingPath("$.code").isEqualTo("character_not_found");
        }
    }

    @Test
    void friendListsArePerUser() throws Exception {
        var a = signUp();
        var b = signUp();

        friend(a, "PUT", "bo");

        assertThat(isFriend(a, "bo")).isTrue();
        assertThat(isFriend(b, "bo")).isFalse();
    }

    @Test
    void needsASession() {
        assertThat(mvc.get().uri("/api/characters")).hasStatus(401);
        assertThat(mvc.put().uri("/api/friends/bo")).hasStatus(401);
    }

    private String signUp() throws Exception {
        var result = mvc.post().uri("/api/auth/sign-up").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"name": "Jamie", "email": "user-%s@example.com", "password": "otterly42"}
                        """.formatted(UUID.randomUUID()))
                .exchange();
        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }

    private MvcTestResult characters(String token) {
        return mvc.get().uri("/api/characters").header("Authorization", "Bearer " + token).exchange();
    }

    private MvcTestResult friend(String token, String method, String slug) {
        var request = method.equals("PUT") ? mvc.put() : mvc.delete();
        return request.uri("/api/friends/" + slug).header("Authorization", "Bearer " + token).exchange();
    }

    private boolean isFriend(String token, String slug) throws Exception {
        var body = characters(token).getResponse().getContentAsString();
        return JsonPath.<List<Boolean>>read(body, "$[?(@.id == '" + slug + "')].isFriend").getFirst();
    }
}
