package com.tracex.backend.repository;

import com.tracex.backend.model.ReworkTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReworkTaskRepository extends JpaRepository<ReworkTask, UUID> {
    Optional<ReworkTask> findFirstByBoard_BoardIdAndStatusNot(String boardId, String status);
}
