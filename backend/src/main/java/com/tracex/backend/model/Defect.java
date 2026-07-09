package com.tracex.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "defects", indexes = {
    @Index(name = "idx_defects_board_id", columnList = "board_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString(exclude = "board")
@EqualsAndHashCode(exclude = "board")
public class Defect {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "board_id", nullable = false, foreignKey = @ForeignKey(name = "fk_defects_boards", value = ConstraintMode.CONSTRAINT))
    @JsonIgnore
    private Board board;

    @Column(nullable = false, length = 100)
    private String component; // e.g. "R34"

    @Column(nullable = false, length = 100)
    private String defect; // e.g. "Missing Component", "Solder Bridge"

    @Column(nullable = false, length = 50)
    private String severity; // "Critical", "High", "Medium", "Low"

    @Column(nullable = false)
    private double confidence; // 0.0 to 1.0

    @Column(name = "bounding_box", nullable = false, columnDefinition = "text")
    @Convert(converter = BoundingBoxConverter.class)
    private BoundingBox boundingBox;

    @Column(name = "image_path", length = 512)
    private String imagePath;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
