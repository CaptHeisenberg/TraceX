package com.tracex.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AIChatRequest {
    @NotBlank(message = "Message must not be blank")
    private String message;

    private String context; // Optional context (defect details, board ID, component)
}
