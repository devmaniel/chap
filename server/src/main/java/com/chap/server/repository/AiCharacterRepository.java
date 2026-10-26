package com.chap.server.repository;

import com.chap.server.entity.AiCharacter;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiCharacterRepository extends JpaRepository<AiCharacter, UUID> {

    Optional<AiCharacter> findBySlug(String slug);
}
