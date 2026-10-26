package com.chap.server.repository;

import com.chap.server.entity.Conversation;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    List<Conversation> findByUserId(UUID userId);

    Optional<Conversation> findByUserIdAndCharacterId(UUID userId, UUID characterId);
}
