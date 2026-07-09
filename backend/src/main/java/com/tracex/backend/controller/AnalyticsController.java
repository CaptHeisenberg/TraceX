package com.tracex.backend.controller;

import com.tracex.backend.model.Board;
import com.tracex.backend.repository.BoardRepository;
import com.tracex.backend.repository.DefectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
@RequestMapping("/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final BoardRepository boardRepository;
    private final DefectRepository defectRepository;

    @GetMapping
    public ResponseEntity<?> getAnalytics() {
        long totalBoards = boardRepository.count();
        
        // Count statuses
        long passedBoards = boardRepository.findAll().stream().filter(b -> "Passed".equalsIgnoreCase(b.getStatus())).count();
        long failedBoards = boardRepository.findAll().stream().filter(b -> "Failed".equalsIgnoreCase(b.getStatus())).count();

        double yieldRate = totalBoards > 0 ? ((double) passedBoards / totalBoards * 100.0) : 100.0;

        // Severity count
        long criticalDefects = defectRepository.countBySeverity("Critical");
        long highDefects = defectRepository.countBySeverity("High");
        long mediumDefects = defectRepository.countBySeverity("Medium");
        long lowDefects = defectRepository.countBySeverity("Low");

        double healthScore = Math.max(50.0, 100.0 - (criticalDefects * 5.0) - (highDefects * 2.0) - (mediumDefects * 0.5));

        // Mock production lines
        List<Map<String, Object>> lineStatus = new ArrayList<>();
        lineStatus.add(createLineMap("SMT-Line 1", "Active", 120, 96.5));
        lineStatus.add(createLineMap("SMT-Line 2", "Active", 110, 94.2));
        lineStatus.add(createLineMap("SMT-Line 3", "Maintenance", 0, 89.0));
        lineStatus.add(createLineMap("SMT-Line 4", "Active", 125, 97.8));

        // Top defects list
        List<Map<String, Object>> topDefects = new ArrayList<>();
        defectRepository.findAll().stream()
                .map(d -> d.getDefect())
                .filter(Objects::nonNull)
                .reduce(new HashMap<String, Integer>(), (map, defect) -> {
                    map.put(defect, map.getOrDefault(defect, 0) + 1);
                    return map;
                }, (map1, map2) -> {
                    map1.putAll(map2);
                    return map1;
                }).entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .limit(5)
                .forEach(entry -> {
                    Map<String, Object> defMap = new HashMap<>();
                    defMap.put("defect", entry.getKey());
                    defMap.put("count", entry.getValue());
                    topDefects.add(defMap);
                });

        if (topDefects.isEmpty()) {
            topDefects.add(createDefectMap("Missing Component", 12));
            topDefects.add(createDefectMap("Solder Bridge", 8));
            topDefects.add(createDefectMap("Misaligned", 6));
            topDefects.add(createDefectMap("Tombstoning", 4));
            topDefects.add(createDefectMap("Insufficient Solder", 3));
        }

        // Daily yield
        List<Map<String, Object>> dailyYields = new ArrayList<>();
        dailyYields.add(createDailyYield("Mon", 450, 432, 96.0));
        dailyYields.add(createDailyYield("Tue", 480, 456, 95.0));
        dailyYields.add(createDailyYield("Wed", 510, 490, 96.1));
        dailyYields.add(createDailyYield("Thu", 490, 465, 94.9));
        dailyYields.add(createDailyYield("Fri", 530, 514, 97.0));
        dailyYields.add(createDailyYield("Sat", 320, 305, 95.3));
        dailyYields.add(createDailyYield("Sun", 150, 145, 96.7));

        // Weekly yield
        List<Map<String, Object>> weeklyYields = new ArrayList<>();
        weeklyYields.add(createWeeklyYield("W1", 94.8));
        weeklyYields.add(createWeeklyYield("W2", 95.6));
        weeklyYields.add(createWeeklyYield("W3", 95.1));
        weeklyYields.add(createWeeklyYield("W4", 96.2));

        // Monthly yield
        List<Map<String, Object>> monthlyYields = new ArrayList<>();
        monthlyYields.add(createMonthlyYield("Jan", 94.2));
        monthlyYields.add(createMonthlyYield("Feb", 95.0));
        monthlyYields.add(createMonthlyYield("Mar", 95.4));
        monthlyYields.add(createMonthlyYield("Apr", 95.8));
        monthlyYields.add(createMonthlyYield("May", 96.1));
        monthlyYields.add(createMonthlyYield("Jun", 96.5));

        // Heatmap coordinate data
        List<Map<String, Object>> heatmapData = new ArrayList<>();
        heatmapData.add(createHeatmapPoint(12.5, 45.2, 0.8, "U4"));
        heatmapData.add(createHeatmapPoint(45.0, 23.1, 0.9, "R34"));
        heatmapData.add(createHeatmapPoint(78.2, 67.5, 0.5, "C12"));
        heatmapData.add(createHeatmapPoint(30.1, 88.0, 0.4, "L2"));
        heatmapData.add(createHeatmapPoint(62.4, 15.6, 0.7, "Q3"));

        // Build result
        Map<String, Object> todayStats = new HashMap<>();
        todayStats.put("boards_inspected", totalBoards);
        todayStats.put("passed", passedBoards);
        todayStats.put("failed", failedBoards);
        todayStats.put("yield_rate", Math.round(yieldRate * 100.0) / 100.0);
        todayStats.put("critical_alerts", criticalDefects);
        todayStats.put("production_speed_avg", 115);

        Map<String, Object> trends = new HashMap<>();
        trends.put("production_trend", List.of(100, 110, 105, 120, 115, 130, 125));
        trends.put("health_trend", List.of(95.0, 94.5, 96.0, 93.8, 95.2, 94.0, healthScore));

        Map<String, Object> result = new HashMap<>();
        result.put("today_stats", todayStats);
        result.put("factory_health_score", Math.round(healthScore * 10.0) / 10.0);
        result.put("line_status", lineStatus);
        result.put("top_defects", topDefects);
        result.put("daily_yields", dailyYields);
        result.put("weekly_yields", weeklyYields);
        result.put("monthly_yields", monthlyYields);
        result.put("heatmap_data", heatmapData);
        result.put("trends", trends);

        return ResponseEntity.ok(result);
    }

    private Map<String, Object> createLineMap(String line, String status, int speed, double yield) {
        Map<String, Object> m = new HashMap<>();
        m.put("line", line);
        m.put("status", status);
        m.put("speed", speed);
        m.put("yield_rate", yield);
        return m;
    }

    private Map<String, Object> createDefectMap(String defect, int count) {
        Map<String, Object> m = new HashMap<>();
        m.put("defect", defect);
        m.put("count", count);
        return m;
    }

    private Map<String, Object> createDailyYield(String day, int inspected, int passed, double yield) {
        Map<String, Object> m = new HashMap<>();
        m.put("day", day);
        m.put("inspected", inspected);
        m.put("passed", passed);
        m.put("yield_rate", yield);
        return m;
    }

    private Map<String, Object> createWeeklyYield(String week, double yield) {
        Map<String, Object> m = new HashMap<>();
        m.put("week", week);
        m.put("yield_rate", yield);
        return m;
    }

    private Map<String, Object> createMonthlyYield(String month, double yield) {
        Map<String, Object> m = new HashMap<>();
        m.put("month", month);
        m.put("yield_rate", yield);
        return m;
    }

    private Map<String, Object> createHeatmapPoint(double x, double y, double intensity, String component) {
        Map<String, Object> m = new HashMap<>();
        m.put("x", x);
        m.put("y", y);
        m.put("intensity", intensity);
        m.put("component", component);
        return m;
    }
}
