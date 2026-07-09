package com.tracex.backend.repository;

import com.tracex.backend.model.Defect;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DefectRepository extends JpaRepository<Defect, UUID> {
    List<Defect> findBySeverityOrderByCreatedAtDesc(String severity);
    List<Defect> findAllByOrderByCreatedAtDesc();
    long countBySeverity(String severity);
}
