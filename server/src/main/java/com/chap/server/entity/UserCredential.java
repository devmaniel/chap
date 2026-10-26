package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "user_credentials")
public class UserCredential {

    @Id
    private UUID userId;

    private String passwordHash;

    protected UserCredential() {
    }

    public UserCredential(UUID userId, String passwordHash) {
        this.userId = userId;
        this.passwordHash = passwordHash;
    }

    public String getPasswordHash() {
        return passwordHash;
    }
}
