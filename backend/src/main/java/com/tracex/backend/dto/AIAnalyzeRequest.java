package com.tracex.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class AIAnalyzeRequest {
    private String board;
    private List<AIDefectItem> defects;
}
