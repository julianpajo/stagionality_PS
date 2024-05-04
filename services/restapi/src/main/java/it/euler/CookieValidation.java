package it.euler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

public class CookieValidation {

    public static boolean validate_cookie(String cookieValue) throws IOException, InterruptedException,
            URISyntaxException, NoSuchAlgorithmException, KeyManagementException, JSONException {

        HttpClient httpClient = HttpInsecureRequest.createInsecureHttpClient();

        URI uri = new URI("https://displacement.euler.local/oauth2/userinfo");
        HttpRequest request = HttpRequest.newBuilder()
                .uri(uri)
                .header("Cookie", "_oauth2_proxy=" + cookieValue)
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        String jsonResponse = response.body();

        JSONObject jsonObject = new JSONObject(jsonResponse);
        JSONArray groups = jsonObject.getJSONArray("groups");
        for (int i = 0; i < groups.length(); i++) {
            String group = groups.getString(i);
            if (group.equals("/SPECIALIST")) {
                return true;
            }
        }

        return false;
    }

}
