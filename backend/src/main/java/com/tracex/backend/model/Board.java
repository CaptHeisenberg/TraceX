package com.tracex.backend.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "boards")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString(exclude = {"defects", "reworks"})
@EqualsAndHashCode(exclude = {"defects", "reworks"})
public class Board {

    @Id
    @Column(name = "board_id", length = 100)
    private String boardId;

    @Column(nullable = false, length = 100)
    private String batch;

    @Column(name = "inspection_time", nullable = false)
    private LocalDateTime inspectionTime;

    @Column(nullable = false, length = 50)
    private String status; // "Passed" or "Failed"

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder.Default
    @OneToMany(mappedBy = "board", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Defect> defects = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "board", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<ReworkTask> reworks = new ArrayList<>();
}
