package it.euler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Value;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

@RestController
public class FeaturesController {

    private static final Logger logger = LoggerFactory.getLogger(FeaturesController.class);

    @Value("${spring.application.geoserver.uri}")
    private String geoserverUri;

    @GetMapping("/getFeatures")
    public String getFeatures(
            @RequestParam float lon_min,
            @RequestParam float lat_min,
            @RequestParam float lon_max,
            @RequestParam float lat_max
    ) throws NoSuchAlgorithmException, KeyManagementException {

        String bbox = lon_min + "%2C" + lat_min + "%2C" + lon_max + "%2C" + lat_max;

        HttpClient httpClient = HttpInsecureRequest.createInsecureHttpClient();

        URI wmsUri = URI.create("https://geoserver.euler.local/geoserver/euler/wms" +
                "?SERVICE=WMS" +
                "&VERSION=1.1.1" +
                "&REQUEST=GetFeatureInfo" +
                "&INFO_FORMAT=application/json" +
                "&QUERY_LAYERS=euler%3Aps_measurements" +
                "&LAYERS=euler%3Aps_measurements" +
                "&FEATURE_COUNT=1" +
                "&X=50" +
                "&Y=50" +
                "&SRS=EPSG%3A4326" +
                "&WIDTH=101" +
                "&HEIGHT=101" +
                "&BBOX=" + bbox);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(wmsUri)
                .GET()
                .build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return response.body();
        } catch (Exception e) {
            return "{\"features\": error} ";
        }


    }
}