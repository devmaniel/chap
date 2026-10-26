package com.chap.server.dto;

/**
 * What the app needs to start one ElevenLabs call as this friend: a short-lived token for the shared agent and
 * the overrides that make the agent this friend. The ElevenLabs key itself never leaves the server.
 */
public record CallPassResponse(String conversationToken, String prompt, String firstMessage, String voiceId) {
}
