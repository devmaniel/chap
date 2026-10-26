package com.chap.server.repository;

import com.chap.server.entity.MessageImage;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MessageImageRepository extends JpaRepository<MessageImage, MessageImage.Key> {

    List<MessageImage> findByMessageIdInOrderByPosition(Collection<UUID> messageIds);
}
