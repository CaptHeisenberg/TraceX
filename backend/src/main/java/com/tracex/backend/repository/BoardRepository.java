package com.tracex.backend.repository;

import com.tracex.backend.model.Board;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoardRepository extends JpaRepository<Board, String> {

    @Query("SELECT b FROM Board b WHERE " +
           "(:search IS NULL OR :search = '' OR LOWER(b.boardId) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(b.batch) LIKE LOWER(CONCAT('%', :search, '%'))) AND " +
           "(:status IS NULL OR :status = 'All' OR b.status = :status) AND " +
           "(:batch IS NULL OR :batch = 'All' OR b.batch = :batch) " +
           "ORDER BY b.inspectionTime DESC")
    List<Board> findFilteredBoards(@Param("search") String search,
                                   @Param("status") String status,
                                   @Param("batch") String batch,
                                   Pageable pageable);
}
