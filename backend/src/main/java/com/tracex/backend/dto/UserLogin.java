package com.tracex.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserLogin {
    @NotBlank(message = "Email must not be blank")
    @Email(message = "Provide a valid email address")
    private String email;

    @NotBlank(message = "Password must not be blank")
    private String password;
}
