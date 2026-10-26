package com.chap.server.service;

import com.chap.server.dto.AuthResponse;
import com.chap.server.dto.SignInRequest;
import com.chap.server.dto.SignUpRequest;
import com.chap.server.dto.UserResponse;
import com.chap.server.entity.User;
import com.chap.server.entity.UserCredential;
import com.chap.server.repository.UserCredentialRepository;
import com.chap.server.repository.UserRepository;
import java.util.Locale;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final UserCredentialRepository userCredentialRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public AuthService(UserRepository userRepository, UserCredentialRepository userCredentialRepository,
            PasswordEncoder passwordEncoder, TokenService tokenService) {
        this.userRepository = userRepository;
        this.userCredentialRepository = userCredentialRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @Transactional
    public AuthResponse signUp(SignUpRequest request) {
        var email = normalize(request.email());
        if (userRepository.existsByEmail(email)) {
            throw new DomainException(DomainException.Kind.CONFLICT, "email_taken",
                    "That email already has an account.");
        }
        var user = userRepository.save(new User(request.name().trim(), email));
        userCredentialRepository.save(new UserCredential(user.getId(), passwordEncoder.encode(request.password())));
        return session(user);
    }

    /** Unknown email and wrong password fail the same way, so sign-in never reveals who has an account. */
    @Transactional(readOnly = true)
    public AuthResponse signIn(SignInRequest request) {
        var user = userRepository.findByEmail(normalize(request.email()))
                .orElseThrow(AuthService::wrongCredentials);
        var credential = userCredentialRepository.findById(user.getId())
                .orElseThrow(AuthService::wrongCredentials);
        if (!passwordEncoder.matches(request.password(), credential.getPasswordHash())) {
            throw wrongCredentials();
        }
        return session(user);
    }

    /** A valid token for an account that no longer exists counts as signed out. */
    @Transactional(readOnly = true)
    public UserResponse me(UUID userId) {
        return userRepository.findById(userId)
                .map(AuthService::toResponse)
                .orElseThrow(() -> new DomainException(DomainException.Kind.UNAUTHORIZED, "unauthorized",
                        "Sign in to continue."));
    }

    private AuthResponse session(User user) {
        return new AuthResponse(tokenService.issue(user.getId()), toResponse(user));
    }

    private static UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail());
    }

    private static String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static DomainException wrongCredentials() {
        return new DomainException(DomainException.Kind.UNAUTHORIZED, "wrong_credentials",
                "Email or password is wrong.");
    }
}
