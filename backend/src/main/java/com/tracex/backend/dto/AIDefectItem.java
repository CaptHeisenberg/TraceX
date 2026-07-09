package com.tracex.backend.dto;

import lombok.Data;

@Data
public class AIDefectItem {
    private String component;
    private String defect;
    private double confidence;
}
