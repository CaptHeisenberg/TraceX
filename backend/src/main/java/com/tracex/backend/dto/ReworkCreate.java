package com.tracex.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReworkCreate {
    @NotBlank(message = "Assignee name must not be blank")
    @JsonProperty("assigned_to")
    private String assignedTo;

    private String remarks;

    @JsonProperty("board_id")
    private String boardId;
}
