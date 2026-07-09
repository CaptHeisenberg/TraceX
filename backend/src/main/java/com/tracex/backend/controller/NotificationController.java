package com.tracex.backend.controller;

import com.tracex.backend.model.Notification;
import com.tracex.backend.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<List<Notification>> getNotifications() {
        List<Notification> list = notificationRepository.findAllByOrderByCreatedAtDesc();
        return ResponseEntity.ok(list);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Notification> updateNotification(
            @PathVariable UUID id,
            @RequestBody Map<String, String> statusBody
    ) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification with ID " + id + " not found."));

        if (statusBody.containsKey("status")) {
            notification.setStatus(statusBody.get("status"));
        }

        Notification updated = notificationRepository.save(notification);
        return ResponseEntity.ok(updated);
    }
}
