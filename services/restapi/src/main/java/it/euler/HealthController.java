package it.euler;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
public class HealthController {

    @GetMapping("/health")
    public String healthCheck() {
        return "Service is healthy";
    }
}
