package com.tracex.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "inspection_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InspectionHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "board_id", nullable = false, length = 100)
    private String boardId;

    @Column(nullable = false, length = 50)
    private String status; // "Passed" or "Failed"

    @Column(name = "operator_name", length = 255)
    private String operatorName;

    @CreationTimestamp
    @Column(name = "inspection_time", nullable = false, updatable = false)
    private LocalDateTime inspectionTime;
}
