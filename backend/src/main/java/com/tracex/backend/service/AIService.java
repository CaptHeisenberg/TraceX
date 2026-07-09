package com.tracex.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class AIService {

    @Value("${app.ollama.url}")
    private String ollamaUrl;

    @Value("${app.ollama.model}")
    private String ollamaModel;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    // Fallback expert database for common SMT PCB defects to guarantee operational integrity
    private static final Map<String, Map<String, String>> FALLBACK_ANALYSIS = new HashMap<>();

    static {
        Map<String, String> missingComponent = new HashMap<>();
        missingComponent.put("severity", "High");
        missingComponent.put("possible_cause", "Pick-and-place nozzle vacuum loss, component adhesion failure, or tape feeder misalignment.");
        missingComponent.put("electrical_impact", "Open circuit. Complete failure of the sub-circuit block associated with this component.");
        missingComponent.put("operator_action", "Manually place replacement component using high-precision rework station with appropriate solder paste.");
        missingComponent.put("preventive_action", "Check pick-and-place nozzle condition, verify component tape feeder tape tension, and clean nozzles.");
        FALLBACK_ANALYSIS.put("Missing Component", missingComponent);

        Map<String, String> solderBridge = new HashMap<>();
        solderBridge.put("severity", "Critical");
        solderBridge.put("possible_cause", "Excessive solder paste deposition, stencil aperture wear, or component placement pressure too high.");
        solderBridge.put("electrical_impact", "Short circuit. Potential to blow upstream power rails or damage neighboring components when powered.");
        solderBridge.put("operator_action", "Use solder wick and fine-tip soldering iron to remove excess solder and isolate the bridged pads.");
        solderBridge.put("preventive_action", "Recalibrate stencil printer alignment, inspect stencil cleanliness, and check paste squeeze pressure.");
        FALLBACK_ANALYSIS.put("Solder Bridge", solderBridge);

        Map<String, String> misaligned = new HashMap<>();
        misaligned.put("severity", "Medium");
        misaligned.put("possible_cause", "Inaccurate vision alignment setup on pick-and-place, board vibration during transit, or paste slippage.");
        misaligned.put("electrical_impact", "Degraded signal integrity, high joint resistance, or potential shorting with nearby vias under load.");
        misaligned.put("operator_action", "Reflow and reposition the component. Ensure pads are aligned properly before applying final heat.");
        misaligned.put("preventive_action", "Clean board registration pins on the pick-and-place conveyor, and check board clamp pressure.");
        FALLBACK_ANALYSIS.put("Misaligned", misaligned);

        Map<String, String> tombstoning = new HashMap<>();
        tombstoning.put("severity", "High");
        tombstoning.put("possible_cause", "Uneven solder paste printing, unbalanced pad design acting as a heat sink, or rapid pre-heating profile.");
        tombstoning.put("electrical_impact", "Open circuit. The component stands vertically, leaving one terminal completely unconnected.");
        tombstoning.put("operator_action", "De-solder, clean the pads, re-apply paste, and re-solder the component flat against the board surface.");
        tombstoning.put("preventive_action", "Adjust reflow profile preheat ramp rate, and audit thermal balance of component pad layouts.");
        FALLBACK_ANALYSIS.put("Tombstoning", tombstoning);

        Map<String, String> insufficientSolder = new HashMap<>();
        insufficientSolder.put("severity", "Medium");
        insufficientSolder.put("possible_cause", "Clogged stencil apertures, low solder paste volume, or insufficient reflow temperature.");
        insufficientSolder.put("electrical_impact", "Weak mechanical joint, high joint resistance, and eventual fatigue crack under thermal cycling.");
        insufficientSolder.put("operator_action", "Re-solder the joint using fine solder wire to achieve proper wetting and a clean concave fillet.");
        insufficientSolder.put("preventive_action", "Perform regular stencil washes and check solder paste viscosity.");
        FALLBACK_ANALYSIS.put("Insufficient Solder", insufficientSolder);
    }

    public Map<String, Object> analyzeDefects(String boardId, List<Map<String, Object>> defects) {
        String prompt = buildPrompt(boardId, defects);

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", ollamaModel);
            requestBody.put("prompt", prompt);
            requestBody.put("stream", false);
            requestBody.put("format", "json");

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            ResponseEntity<String> response = restTemplate.exchange(ollamaUrl, HttpMethod.POST, entity, String.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String responseText = root.path("response").asText("");

                try {
                    JsonNode parsedNode = objectMapper.readTree(responseText);
                    Map<String, Object> result = new HashMap<>();
                    if (parsedNode.has("analysis")) {
                        result.put("analysis", objectMapper.convertValue(parsedNode.get("analysis"), List.class));
                        return result;
                    } else {
                        List<JsonNode> list = new ArrayList<>();
                        list.add(parsedNode);
                        result.put("analysis", list);
                        return result;
                    }
                } catch (Exception ex) {
                    log.warn("Failed to parse Ollama JSON response text, trying secondary regex search: {}", responseText);
                    // Fallback to extract first JSON object/array from responseText if nested raw
                    int start = responseText.indexOf("{");
                    int end = responseText.lastIndexOf("}") + 1;
                    if (start != -1 && end != -1) {
                        JsonNode parsedNode = objectMapper.readTree(responseText.substring(start, end));
                        Map<String, Object> result = new HashMap<>();
                        if (parsedNode.has("analysis")) {
                            result.put("analysis", objectMapper.convertValue(parsedNode.get("analysis"), List.class));
                            return result;
                        } else {
                            List<JsonNode> list = new ArrayList<>();
                            list.add(parsedNode);
                            result.put("analysis", list);
                            return result;
                        }
                    }
                }
            }
            log.warn("Ollama returned non-200 or empty body. Triggering fallback analysis.");
        } catch (Exception ex) {
            log.warn("Ollama communication failure ({}). Triggering fallback analysis.", ex.getMessage());
        }

        return generateFallbackAnalysis(defects);
    }

    private String buildPrompt(String boardId, List<Map<String, Object>> defects) {
        try {
            String defectsJson = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(defects);
            return "You are an SMT PCB manufacturing expert.\n" +
                    "Given the following detected defects on Board " + boardId + ":\n" +
                    defectsJson + "\n\n" +
                    "Return a JSON object containing the analysis. The root of the JSON should contain a key \"analysis\" which is a list of objects, one for each defect analyzed.\n" +
                    "Each object in the list must have the following keys:\n" +
                    "- \"component\": (string matching the component name)\n" +
                    "- \"defect\": (string matching the defect name)\n" +
                    "- \"severity\": (string: Critical, High, Medium, Low)\n" +
                    "- \"possible_cause\": (brief manufacturing cause)\n" +
                    "- \"electrical_impact\": (brief electrical impact)\n" +
                    "- \"operator_action\": (recommended operator action)\n" +
                    "- \"preventive_action\": (preventive action for production line)\n\n" +
                    "Return ONLY valid JSON. No conversational wrapper or markdown block formats.";
        } catch (Exception e) {
            return "Analyze SMT defects on board " + boardId;
        }
    }

    private Map<String, Object> generateFallbackAnalysis(List<Map<String, Object>> defects) {
        List<Map<String, Object>> analysisList = new ArrayList<>();

        for (Map<String, Object> d : defects) {
            String component = (String) d.getOrDefault("component", "Unknown");
            String defectType = (String) d.getOrDefault("defect", "Unknown");

            Map<String, String> meta = FALLBACK_ANALYSIS.get(defectType);
            if (meta == null) {
                meta = new HashMap<>();
                meta.put("severity", "Medium");
                meta.put("possible_cause", "General mechanical failure or placement error for " + defectType + ".");
                meta.put("electrical_impact", "Potential degradation of circuit performance or reliability.");
                meta.put("operator_action", "Inspect " + component + " visually and rework if connection is unstable.");
                meta.put("preventive_action", "Audit pick-and-place calibration parameters and PCB dimensions.");
            }

            Map<String, Object> item = new HashMap<>();
            item.put("component", component);
            item.put("defect", defectType);
            item.put("severity", meta.get("severity"));
            item.put("possible_cause", meta.get("possible_cause"));
            item.put("electrical_impact", meta.get("electrical_impact"));
            item.put("operator_action", meta.get("operator_action"));
            item.put("preventive_action", meta.get("preventive_action"));

            analysisList.add(item);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("analysis", analysisList);
        return result;
    }

    public String chatWithModel(String message, String context) {
        StringBuilder promptBuilder = new StringBuilder();
        promptBuilder.append("You are TraceX AI, an SMT manufacturing co-pilot. ");
        promptBuilder.append("Troubleshoot defects, calibrate machines, and answer custom questions. ");
        promptBuilder.append("Keep explanations highly technical, structured, and under 3 sentences maximum.\n\n");

        if (context != null && !context.trim().isEmpty()) {
            promptBuilder.append("[Context for current discussion]:\n").append(context).append("\n\n");
        }

        promptBuilder.append("[User Question]: ").append(message).append("\n\n");
        promptBuilder.append("Response:");

        String prompt = promptBuilder.toString();

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", ollamaModel);
            requestBody.put("prompt", prompt);
            requestBody.put("stream", false);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            ResponseEntity<String> response = restTemplate.exchange(ollamaUrl, HttpMethod.POST, entity, String.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                return root.path("response").asText("No response was returned by Ollama.");
            }
        } catch (Exception ex) {
            log.warn("Ollama chat communication failure ({}). Returning fallback answer.", ex.getMessage());
        }

        return getFallbackChatAnswer(message, context);
    }

    private String getFallbackChatAnswer(String message, String context) {
        String msg = message.toLowerCase();
        if (msg.contains("solder bridge")) {
            return "TraceX Fallback Assistant:\n\nSolder bridging is typically caused by excessive solder paste deposition, misaligned stencil printing, or high placement pressure.\n\nImmediate Actions:\n1. Use a solder wick and a fine-tip iron to remove the short.\n2. Verify printing pressure and stencil cleanliness (under-stencil wipe frequency).";
        } else if (msg.contains("tombstoning") || msg.contains("tombstone")) {
            return "TraceX Fallback Assistant:\n\nTombstoning occurs when unbalanced surface tension forces pull a small component up during reflow, leaving it standing vertically on one pad.\n\nPossible Causes:\n1. Uneven solder paste volume on pads.\n2. Unequal thermal mass of copper connections to pads.\n3. Too fast a temperature ramp rate in the pre-heat zone.\n\nActions:\n1. De-solder, clean pads, and manual reflow.\n2. Slow down the reflow preheat profile.";
        } else if (msg.contains("misalign") || msg.contains("misaligned")) {
            return "TraceX Fallback Assistant:\n\nComponent misalignment is caused by machine tracking failures, board vibration, or nozzle slippage.\n\nActions:\n1. Re-run pick-and-place camera vision check.\n2. Realign component pins flatly on pads before reflowing.";
        }
        return "TraceX Fallback Assistant:\n\nOllama AI engine is currently unreachable. As an SMT expert rule base: verify machine calibration, paste print thickness, and reflow thermal profile parameters.";
    }
}
