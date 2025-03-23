package ch.nb.business;

public class PokemonSpecie {

    public PokemonSpecie(String name, Stats stats) {
        this.name = name;
        this.stats = stats;
    }

    private String name;

    private Stats stats;

    public String getName() {
        return name;
    }
}
