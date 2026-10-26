package com.chap.server.controller;

import com.chap.server.dto.CharacterResponse;
import com.chap.server.service.CharacterService;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CharacterController {

    private final CharacterService characterService;

    public CharacterController(CharacterService characterService) {
        this.characterService = characterService;
    }

    @GetMapping("/api/characters")
    List<CharacterResponse> list(@AuthenticationPrincipal UUID userId) {
        return characterService.list(userId);
    }
}
