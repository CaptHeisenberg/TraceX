package com.tracex.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AlertResolveRequest {
    @NotBlank(message = "Board ID must not be blank")
    @JsonProperty("board_id")
    private String boardId;

    private String remarks;

    @NotBlank(message = "Status must not be blank")
    private String status; // "Resolved", "Reviewed"
}
