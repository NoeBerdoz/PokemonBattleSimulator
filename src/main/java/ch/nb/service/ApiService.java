package ch.nb.service;

import ch.nb.business.PokemonSpecie;
import ch.nb.business.Stats;
import com.google.gson.*;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class ApiService {

    private static Stats serializeStats(JsonArray statsJsonArray) {

        Stats stats = new Stats();

        for (JsonElement element : statsJsonArray) {

            JsonObject jsonObject = element.getAsJsonObject();

            int statValue = jsonObject.get("base_stat").getAsInt();
            String statName = jsonObject.getAsJsonObject("stat").get("name").getAsString();

            if (statName.equals("hp")) {
                stats.setHp(statValue);
            }

            if (statName.equals("speed")) {
                stats.setSpeed(statValue);
            }

            if (statName.equals("attack")) {
                stats.setAttack(statValue);
            }

            if (statName.equals("defense")) {
                stats.setDefense(statValue);
            }

            if (statName.equals("special-attack")) {
                stats.setSpecialAttack(statValue);
            }

            if (statName.equals("special-defense")) {
                stats.setSpecialDefense(statValue);
            }

        }

        return stats;
    }

    public static PokemonSpecie serializePokemonSpecie(String pokemonJsonString) {

        JsonObject jsonResponse = JsonParser.parseString(pokemonJsonString).getAsJsonObject();

        JsonArray statsJsonArray = jsonResponse.getAsJsonArray("stats");

        Stats stats = serializeStats(statsJsonArray);

        String name = jsonResponse.get("name").getAsString();

        return new PokemonSpecie(name, stats);
    }

    public static HttpResponse<String> sendHttpRequest(String endpoint) throws IOException, InterruptedException {

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://pokeapi.co/api/v2/" + endpoint))
                .GET()
                .build();

        try {

            return HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());

        } catch (IOException | InterruptedException error) {

            error.printStackTrace();
            throw error;

        }
    }
}
