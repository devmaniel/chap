package com.chap.server.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CallRecordRequest(@NotNull @Min(0) Integer durationSeconds) {
}
