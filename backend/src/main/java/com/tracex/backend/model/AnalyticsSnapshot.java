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
@Table(name = "analytics_snapshots")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyticsSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime timestamp;

    @Column(name = "factory_health_score", nullable = false)
    private double factoryHealthScore;

    @Column(name = "boards_inspected", nullable = false)
    private int boardsInspected;

    @Column(nullable = false)
    private int passed;

    @Column(nullable = false)
    private int failed;

    @Column(name = "yield_rate", nullable = false)
    private double yieldRate;

    @Column(name = "critical_alerts", nullable = false)
    private int criticalAlerts;
}
