package com.tracex.backend.controller;

import com.tracex.backend.dto.ReworkCreate;
import com.tracex.backend.model.Board;
import com.tracex.backend.model.ReworkTask;
import com.tracex.backend.repository.BoardRepository;
import com.tracex.backend.repository.ReworkTaskRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/boards")
@RequiredArgsConstructor
public class BoardController {

    private final BoardRepository boardRepository;
    private final ReworkTaskRepository reworkTaskRepository;

    @GetMapping
    public ResponseEntity<List<Board>> getBoards(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String batch,
            @RequestParam(defaultValue = "0") int skip,
            @RequestParam(defaultValue = "20") int limit
    ) {
        int page = limit > 0 ? (skip / limit) : 0;
        int size = limit > 0 ? limit : 20;
        PageRequest pageRequest = PageRequest.of(page, size);
        List<Board> boards = boardRepository.findFilteredBoards(search, status, batch, pageRequest);
        return ResponseEntity.ok(boards);
    }

    @GetMapping("/{boardId}")
    public ResponseEntity<Board> getBoard(@PathVariable String boardId) {
        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Board with ID " + boardId + " not found."));
        return ResponseEntity.ok(board);
    }

    @PostMapping("/{boardId}/rework")
    public ResponseEntity<ReworkTask> assignRework(
            @PathVariable String boardId,
            @Valid @RequestBody ReworkCreate reworkRequest
    ) {
        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Board with ID " + boardId + " not found."));

        ReworkTask rework = ReworkTask.builder()
                .board(board)
                .assignedTo(reworkRequest.getAssignedTo())
                .remarks(reworkRequest.getRemarks())
                .status("Assigned")
                .build();

        ReworkTask savedRework = reworkTaskRepository.save(rework);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedRework);
    }
}
