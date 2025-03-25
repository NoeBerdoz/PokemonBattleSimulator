package ch.nb;

import ch.nb.business.PokemonSpecie;
import ch.nb.persistence.DataManager;
import ch.nb.service.ApiService;
import ch.nb.utils.SimpleLogger;

import java.io.IOException;
import java.net.http.HttpResponse;

public class Main {
    public static void main(String[] args) throws IOException, InterruptedException {
        System.out.println("Hello, World!");

        DataManager dataManager = new DataManager();

        for (int pokemonIndex = 1; pokemonIndex <=10; pokemonIndex++) {
            HttpResponse<String> response = ApiService.sendHttpRequest("pokemon/" + pokemonIndex);
            PokemonSpecie pokemonSpecie = ApiService.serializePokemonSpecie(response.body());

            try {
                dataManager.insertPokemonSpecie(pokemonSpecie);
                SimpleLogger.info("[+] Added " + pokemonSpecie.getName() + " [" + pokemonIndex + "]");
            } catch (Exception error) {
                SimpleLogger.error(error.getMessage());
            }
        }
    }
}