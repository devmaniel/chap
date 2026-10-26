package com.chap.server.repository;

import com.chap.server.entity.UserFriend;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserFriendRepository extends JpaRepository<UserFriend, UserFriend.Key> {

    List<UserFriend> findByUserId(UUID userId);
}
