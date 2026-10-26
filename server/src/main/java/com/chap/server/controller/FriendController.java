package com.chap.server.controller;

import com.chap.server.service.CharacterService;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/friends/{slug}")
public class FriendController {

    private final CharacterService characterService;

    public FriendController(CharacterService characterService) {
        this.characterService = characterService;
    }

    @PutMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void add(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        characterService.addFriend(userId, slug);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void remove(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        characterService.removeFriend(userId, slug);
    }
}
