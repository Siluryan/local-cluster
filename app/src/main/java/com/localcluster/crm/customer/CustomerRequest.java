package com.localcluster.crm.customer;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CustomerRequest(
    @NotBlank String name,
    @Email @NotBlank String email,
    @NotBlank String company,
    @NotBlank String status
) {
}
