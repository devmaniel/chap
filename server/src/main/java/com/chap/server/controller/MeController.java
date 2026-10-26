package com.chap.server.controller;

import com.chap.server.dto.UserResponse;
import com.chap.server.service.AuthService;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MeController {

    private final AuthService authService;

    public MeController(AuthService authService) {
        this.authService = authService;
    }

    /** The app calls this on start to check its stored session. */
    @GetMapping("/api/me")
    UserResponse me(@AuthenticationPrincipal UUID userId) {
        return authService.me(userId);
    }
}
