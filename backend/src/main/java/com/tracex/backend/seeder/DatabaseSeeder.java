package com.tracex.backend.seeder;

import com.tracex.backend.model.*;
import com.tracex.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final BoardRepository boardRepository;
    private final DefectRepository defectRepository;
    private final ReworkTaskRepository reworkTaskRepository;
    private final NotificationRepository notificationRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        log.info("Checking database data state...");

        // 1. Seed User
        if (userRepository.count() == 0) {
            log.info("Database is empty. Seeding default operator credential...");
            User operator = User.builder()
                    .name("Line Supervisor")
                    .email("operator@tracex.com")
                    .passwordHash(passwordEncoder.encode("Password123!"))
                    .build();
            userRepository.save(operator);
        }

        // 2. Seed Boards, Defects, and Reworks
        if (boardRepository.count() == 0) {
            log.info("Seeding default SMT PCB board inspection runs...");

            // Board 1: Passed
            Board board1 = Board.builder()
                    .boardId("PCB-20399")
                    .batch("BATCH-A109")
                    .inspectionTime(LocalDateTime.now().minusMinutes(20))
                    .status("Passed")
                    .build();
            boardRepository.save(board1);

            // Board 2: Failed (Critical - Solder Bridge)
            Board board2 = Board.builder()
                    .boardId("PCB-20398")
                    .batch("BATCH-A109")
                    .inspectionTime(LocalDateTime.now().minusMinutes(40))
                    .status("Failed")
                    .build();
            boardRepository.save(board2);

            Defect defect2 = Defect.builder()
                    .board(board2)
                    .component("R34")
                    .defect("Solder Bridge")
                    .severity("Critical")
                    .confidence(0.98)
                    .boundingBox(new BoundingBox(10.0, 15.0, 20.0, 20.0))
                    .build();
            defectRepository.save(defect2);

            ReworkTask rework2 = ReworkTask.builder()
                    .board(board2)
                    .assignedTo("System Operator")
                    .status("Resolved")
                    .remarks("Directly resolved and cleared via inspection console.")
                    .build();
            reworkTaskRepository.save(rework2);

            // Board 3: Passed
            Board board3 = Board.builder()
                    .boardId("PCB-20397")
                    .batch("BATCH-A109")
                    .inspectionTime(LocalDateTime.now().minusHours(1))
                    .status("Passed")
                    .build();
            boardRepository.save(board3);

            // Board 4: Failed (Medium - Misaligned)
            Board board4 = Board.builder()
                    .boardId("PCB-20396")
                    .batch("BATCH-B110")
                    .inspectionTime(LocalDateTime.now().minusHours(2))
                    .status("Failed")
                    .build();
            boardRepository.save(board4);

            Defect defect4 = Defect.builder()
                    .board(board4)
                    .component("Q3")
                    .defect("Misaligned")
                    .severity("Medium")
                    .confidence(0.88)
                    .boundingBox(new BoundingBox(45.0, 30.0, 15.0, 15.0))
                    .build();
            defectRepository.save(defect4);

            // Board 5: Failed (High - Tombstoning)
            Board board5 = Board.builder()
                    .boardId("PCB-20391")
                    .batch("BATCH-B110")
                    .inspectionTime(LocalDateTime.now().minusHours(3))
                    .status("Failed")
                    .build();
            boardRepository.save(board5);

            Defect defect5 = Defect.builder()
                    .board(board5)
                    .component("U4")
                    .defect("Tombstoning")
                    .severity("High")
                    .confidence(0.92)
                    .boundingBox(new BoundingBox(60.0, 55.0, 25.0, 25.0))
                    .build();
            defectRepository.save(defect5);

            ReworkTask rework5 = ReworkTask.builder()
                    .board(board5)
                    .assignedTo("Operator Dave")
                    .status("In Progress")
                    .remarks("De-solder, clean the pads, re-apply paste, and re-solder the component flat against the board surface.")
                    .build();
            reworkTaskRepository.save(rework5);
        }

        // 3. Seed Notifications
        if (notificationRepository.count() == 0) {
            log.info("Seeding manufacturing warning alarms and history logs...");

            notificationRepository.save(Notification.builder()
                    .title("Critical Defect Flagged")
                    .message("Board PCB-20398 inspect failure: Solder Bridge detected on component R34. Line 1 paused.")
                    .status("unread")
                    .build());

            notificationRepository.save(Notification.builder()
                    .title("Line Status Alert")
                    .message("SMT-Line 3 conveyor belt calibration scheduled for 14:00 PM.")
                    .status("unread")
                    .build());

            notificationRepository.save(Notification.builder()
                    .title("Quality Metric Compiling")
                    .message("Factory health score dropped below 90% target threshold due to component anomalies.")
                    .status("unread")
                    .build());

            notificationRepository.save(Notification.builder()
                    .title("Report Compiled")
                    .message("Monthly yield report for June ready for download.")
                    .status("read")
                    .build());
        }

        log.info("Database seeding checked and initialized successfully!");
    }
}
