package com.chap.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record SignUpRequest(
        @NotBlank @Size(max = 50) String name,
        // Same rule as the app's sign-up form.
        @NotNull @Pattern(regexp = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$") String email,
        // 72 is BCrypt's limit.
        @NotNull @Size(min = 8, max = 72) String password) {
}
