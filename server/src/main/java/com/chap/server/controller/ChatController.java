package com.chap.server.controller;

import com.chap.server.dto.CallPassResponse;
import com.chap.server.dto.CallRecordRequest;
import com.chap.server.dto.ChatResponse;
import com.chap.server.dto.ImageData;
import com.chap.server.dto.MessageResponse;
import com.chap.server.dto.SendMessageRequest;
import com.chap.server.service.ChatService;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** Chats are addressed by the friend's slug, e.g. {@code /api/chats/mina}. */
@RestController
@RequestMapping("/api/chats")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping
    List<ChatResponse> list(@AuthenticationPrincipal UUID userId) {
        return chatService.list(userId);
    }

    @PutMapping("/{slug}")
    ChatResponse start(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        return chatService.start(userId, slug);
    }

    @GetMapping("/{slug}")
    ChatResponse get(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        return chatService.get(userId, slug);
    }

    @GetMapping("/{slug}/messages")
    List<MessageResponse> messages(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        return chatService.messages(userId, slug);
    }

    @PostMapping("/{slug}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void markRead(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        chatService.markRead(userId, slug);
    }

    @PostMapping("/{slug}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    MessageResponse send(@AuthenticationPrincipal UUID userId, @PathVariable String slug,
            @Valid @RequestBody SendMessageRequest request) {
        return chatService.send(userId, slug, request);
    }

    /** A short-lived pass for one voice call with this friend. */
    @PostMapping("/{slug}/call")
    CallPassResponse call(@AuthenticationPrincipal UUID userId, @PathVariable String slug) {
        return chatService.callPass(userId, slug);
    }

    @PostMapping("/{slug}/calls")
    @ResponseStatus(HttpStatus.CREATED)
    MessageResponse saveCall(@AuthenticationPrincipal UUID userId, @PathVariable String slug,
            @Valid @RequestBody CallRecordRequest request) {
        return chatService.saveCall(userId, slug, request);
    }

    /** Plain POST, or multipart with up to 4 {@code images}: the latest message's photos, read from the phone. */
    @PostMapping("/{slug}/reply")
    MessageResponse reply(@AuthenticationPrincipal UUID userId, @PathVariable String slug,
            @RequestParam(name = "images", required = false) List<MultipartFile> images) throws IOException {
        var photos = new ArrayList<ImageData>();
        for (var image : images == null ? List.<MultipartFile>of() : images) {
            photos.add(new ImageData(image.getContentType(), image.getBytes()));
        }
        return chatService.reply(userId, slug, photos);
    }
}
