package com.tracex.backend.controller;

import com.tracex.backend.dto.AIAnalyzeRequest;
import com.tracex.backend.dto.AIDefectItem;
import com.tracex.backend.dto.AIChatRequest;
import com.tracex.backend.service.AIService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/ai")
@RequiredArgsConstructor
public class AIController {

    private final AIService aiService;

    @PostMapping("/analyze")
    public ResponseEntity<?> analyzeDefects(@RequestBody AIAnalyzeRequest req) {
        if (req.getDefects() == null || req.getDefects().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Defects list cannot be empty");
        }

        List<Map<String, Object>> defectsMap = new ArrayList<>();
        for (AIDefectItem item : req.getDefects()) {
            Map<String, Object> d = new HashMap<>();
            d.put("component", item.getComponent());
            d.put("defect", item.getDefect());
            d.put("confidence", item.getConfidence());
            defectsMap.add(d);
        }

        Map<String, Object> result = aiService.analyzeDefects(req.getBoard(), defectsMap);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/chat")
    public ResponseEntity<?> chat(@RequestBody AIChatRequest req) {
        String answer = aiService.chatWithModel(req.getMessage(), req.getContext());
        Map<String, String> response = new HashMap<>();
        response.put("response", answer);
        return ResponseEntity.ok(response);
    }
}
