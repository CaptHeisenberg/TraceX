package com.tracex.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "reworks", indexes = {
    @Index(name = "idx_reworks_board_id", columnList = "board_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString(exclude = "board")
@EqualsAndHashCode(exclude = "board")
public class ReworkTask {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "board_id", nullable = false, foreignKey = @ForeignKey(name = "fk_reworks_boards", value = ConstraintMode.CONSTRAINT))
    @JsonIgnore
    private Board board;

    @Column(name = "assigned_to", nullable = false, length = 255)
    private String assignedTo;

    @Column(nullable = false, length = 50)
    @Builder.Default
    private String status = "Assigned"; // "Assigned", "In Progress", "Resolved"

    @Column(columnDefinition = "text")
    private String remarks;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
