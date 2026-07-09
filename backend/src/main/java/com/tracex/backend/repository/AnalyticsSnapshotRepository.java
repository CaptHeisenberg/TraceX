package com.tracex.backend.repository;

import com.tracex.backend.model.AnalyticsSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AnalyticsSnapshotRepository extends JpaRepository<AnalyticsSnapshot, UUID> {
    Optional<AnalyticsSnapshot> findFirstByOrderByTimestampDesc();
}
