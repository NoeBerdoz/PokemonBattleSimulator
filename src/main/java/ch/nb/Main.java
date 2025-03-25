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



        HttpResponse<String> response = ApiService.sendHttpRequest("pokemon/1");

        String body = response.body();

        PokemonSpecie pokemonSpecie = ApiService.serializePokemonSpecie(response.body());

        System.out.println(pokemonSpecie.getName());

        DataManager dataManager = new DataManager();

        try {
            dataManager.insertPokemonSpecie(pokemonSpecie);
        } catch (Exception error) {
            SimpleLogger.error(error.getMessage());
        }




    }
}