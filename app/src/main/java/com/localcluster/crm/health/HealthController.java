package com.localcluster.crm.health;

import java.time.Instant;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HealthController {

  @GetMapping("/health")
  public Map<String, Object> health() {
    return Map.of(
        "service", "crm-api",
        "status", "ok",
        "timestamp", Instant.now().toString()
    );
  }
}
