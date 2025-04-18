package ch.nb;

import ch.nb.business.PokemonSpecie;
import ch.nb.persistence.DataManager;
import ch.nb.service.ApiService;
import ch.nb.utils.SimpleLogger;

import java.io.IOException;
import java.net.http.HttpResponse;

public class Main {
    public static void main(String[] args) throws IOException, InterruptedException {
        SimpleLogger.info("------ STARTING Pokemon Inserter -----");

        DataManager dataManager = new DataManager();

        // Demonstration of retrieving an XML present in an XMLTYPE COLUMN from the database
        String xmlDocument = dataManager.getBattleLogXml(10000);
        System.out.println(xmlDocument);

        // insertPokemon(10);


    }

    public static void insertPokemon(int number) throws IOException, InterruptedException {

        DataManager dataManager = new DataManager();

        for (int pokemonIndex = 1; pokemonIndex <=10; pokemonIndex++) {
            HttpResponse<String> response = ApiService.sendHttpRequest("pokemon/" + pokemonIndex);
            PokemonSpecie pokemonSpecie = ApiService.serializePokemonSpecie(response.body());

            try {
                dataManager.insertPokemonSpecie(pokemonSpecie);
                // SimpleLogger.info("[+] Added " + pokemonSpecie.getName() + " [" + pokemonIndex + "]");
            } catch (Exception error) {
                SimpleLogger.error(error.getMessage());
            }
        }

    }
}