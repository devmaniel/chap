package com.chap.server.repository;

import com.chap.server.entity.Message;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MessageRepository extends JpaRepository<Message, UUID> {

    List<Message> findByConversationIdOrderBySentAtAsc(UUID conversationId);

    /** Newest first. */
    List<Message> findTop30ByConversationIdOrderBySentAtDesc(UUID conversationId);

    Optional<Message> findFirstByConversationIdOrderBySentAtDesc(UUID conversationId);

    long countByConversationIdAndSender(UUID conversationId, Message.Sender sender);

    long countByConversationIdAndSenderAndSentAtAfter(UUID conversationId, Message.Sender sender, Instant after);
}
