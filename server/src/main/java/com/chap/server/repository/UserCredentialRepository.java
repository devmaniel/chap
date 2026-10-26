package com.chap.server.repository;

import com.chap.server.entity.UserCredential;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserCredentialRepository extends JpaRepository<UserCredential, UUID> {
}
