package com.tracex.backend.model;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class BoundingBoxConverter implements AttributeConverter<BoundingBox, String> {

    private final static ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(BoundingBox meta) {
        try {
            return objectMapper.writeValueAsString(meta);
        } catch (JsonProcessingException ex) {
            return "{\"x\":0.0,\"y\":0.0,\"width\":0.0,\"height\":0.0}";
        }
    }

    @Override
    public BoundingBox convertToEntityAttribute(String dbData) {
        try {
            return objectMapper.readValue(dbData, BoundingBox.class);
        } catch (Exception ex) {
            return new BoundingBox(0.0, 0.0, 0.0, 0.0);
        }
    }
}
