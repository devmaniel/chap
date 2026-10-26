package com.chap.server.controller;

import com.chap.server.dto.HealthResponse;
import com.chap.server.service.HealthService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @GetMapping("/api/health")
    HealthResponse health() {
        healthService.check();
        return new HealthResponse("ok");
    }
}
