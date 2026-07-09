package com.tracex.backend.repository;

import com.tracex.backend.model.InspectionHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface InspectionHistoryRepository extends JpaRepository<InspectionHistory, UUID> {
    List<InspectionHistory> findTop5ByOrderByInspectionTimeDesc();
}
