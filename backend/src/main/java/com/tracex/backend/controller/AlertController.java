package com.tracex.backend.controller;

import com.tracex.backend.dto.AlertResolveRequest;
import com.tracex.backend.model.Board;
import com.tracex.backend.model.Defect;
import com.tracex.backend.model.ReworkTask;
import com.tracex.backend.repository.BoardRepository;
import com.tracex.backend.repository.DefectRepository;
import com.tracex.backend.repository.ReworkTaskRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/alerts")
@RequiredArgsConstructor
public class AlertController {

    private final DefectRepository defectRepository;
    private final BoardRepository boardRepository;
    private final ReworkTaskRepository reworkTaskRepository;

    @GetMapping
    public ResponseEntity<List<Defect>> getAlerts(@RequestParam(required = false) String severity) {
        List<Defect> defects;
        if (severity != null && !severity.isEmpty() && !severity.equalsIgnoreCase("All")) {
            defects = defectRepository.findBySeverityOrderByCreatedAtDesc(severity);
        } else {
            defects = defectRepository.findAllByOrderByCreatedAtDesc();
        }
        return ResponseEntity.ok(defects);
    }

    @PostMapping("/resolve")
    public ResponseEntity<?> resolveAlert(@Valid @RequestBody AlertResolveRequest req) {
        Board board = boardRepository.findById(req.getBoardId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Board with ID " + req.getBoardId() + " not found."));

        if ("Resolved".equalsIgnoreCase(req.getStatus())) {
            board.setStatus("Passed");
            boardRepository.save(board);
        }

        Optional<ReworkTask> activeRework = reworkTaskRepository.findFirstByBoard_BoardIdAndStatusNot(req.getBoardId(), "Resolved");
        if (activeRework.isPresent()) {
            ReworkTask rework = activeRework.get();
            rework.setStatus(req.getStatus());
            rework.setRemarks(req.getRemarks() != null ? req.getRemarks() : "Resolved via Alert resolution screen");
            reworkTaskRepository.save(rework);
        } else {
            ReworkTask rework = ReworkTask.builder()
                    .board(board)
                    .assignedTo("System Operator")
                    .status(req.getStatus())
                    .remarks(req.getRemarks() != null ? req.getRemarks() : "Resolved directly via Alert resolution screen")
                    .build();
            reworkTaskRepository.save(rework);
        }

        Map<String, String> response = new HashMap<>();
        response.put("message", "Alert marked as resolved. Board status updated.");
        response.put("board_status", board.getStatus());
        return ResponseEntity.ok(response);
    }
}
