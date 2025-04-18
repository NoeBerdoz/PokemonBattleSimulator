package ch.nb.persistence;

import ch.nb.business.PokemonSpecie;
import ch.nb.business.Stats;
import ch.nb.persistence.connection.DatabaseConnection;
import ch.nb.utils.SimpleLogger;

import java.sql.*;

public class DataManager {

    private int insertStats(Stats stats) throws SQLException {
        String sqlQuery = "INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (?, ?, ?, ?, ?, ?)";
        int hpIndex = 1;
        int speedIndex = 2;
        int attackIndex = 3;
        int defenseIndex = 4;
        int speAttackIndex = 5;
        int speDefenseIndex = 6;

        Connection connection = DatabaseConnection.getConnection();

        try {
            PreparedStatement statement = connection.prepareStatement(sqlQuery, new String[]{"ID"});
            statement.setInt(hpIndex, stats.getHp());
            statement.setInt(speedIndex, stats.getSpeed());
            statement.setInt(attackIndex, stats.getAttack());
            statement.setInt(defenseIndex, stats.getDefense());
            statement.setInt(speAttackIndex, stats.getSpecialAttack());
            statement.setInt(speDefenseIndex, stats.getSpecialDefense());

            // Get the generated row ID and returns it
            int affectedRows = statement.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = statement.getGeneratedKeys();
                if (generatedKeys.next()) {
                    String generatedId = generatedKeys.getString(1);

                    String rawSql = String.format(
                            "INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (%d, %d, %d, %d, %d, %d);",
                            stats.getHp(), stats.getSpeed(), stats.getAttack(), stats.getDefense(), stats.getSpecialAttack(), stats.getSpecialDefense()
                    );
                    System.out.println(rawSql);

                    return Integer.parseInt(generatedId);
                }
            }

        } catch (SQLException error) {
            SimpleLogger.error(error.getMessage());
        }

        // In case of an issue, returns a not valid id
        return -1;
    }

    public void insertPokemonSpecie(PokemonSpecie pokemonSpecie) throws SQLException {

        String sqlQuery = "INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES (?, ?)";
        int nameIndex = 1;
        int statIndex = 2;

        Connection connection = DatabaseConnection.getConnection();

        try {
            int statForeignKey = this.insertStats(pokemonSpecie.getStats());

            PreparedStatement statement = connection.prepareStatement(sqlQuery, new String[]{"ID"});
            statement.setString(nameIndex, pokemonSpecie.getName());
            statement.setInt(statIndex, statForeignKey);

            String rawSql = String.format(
                    "INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('%s', %d);",
                    pokemonSpecie.getName(), statForeignKey
            );
            System.out.println(rawSql);

            statement.executeUpdate();

        } catch (SQLException error) {
            SimpleLogger.error(error.getMessage());
        }
    }

    public String getBattleLogXml(int battleId) {

        String sqlQuery = "SELECT * FROM BATTLE_LOG WHERE BATTLE_ID = ? ORDER BY CREATED_AT DESC FETCH FIRST 1 ROW ONLY";

        String xmlString = null;
        SQLXML sqlxml = null;

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sqlQuery)) {

            statement.setInt(1, battleId);

            try (ResultSet resultSet = statement.executeQuery()) {

                if (resultSet.next()) {

                    sqlxml = resultSet.getSQLXML("XML_DOCUMENT");
                    if (sqlxml != null) {

                        xmlString = sqlxml.getString();

                    } else {
                        SimpleLogger.warning("XML_DOCUMENT is NULL for battle ID: " + battleId);
                    }
                } else {
                    SimpleLogger.error("No battle log found for battle ID: " + battleId);
                }
            }
        } catch (SQLException error) {
            SimpleLogger.error("Error retrieving XML log for battle ID " + battleId + ": " + error.getMessage());

        } finally {
            // JDBC standard JDBC require to free resources around SQLXML manually
            if (sqlxml != null) {
                try {
                    sqlxml.free();
                } catch (SQLException e) {
                    SimpleLogger.error("Error freeing SQLXML resource: " + e.getMessage());
                }
            }
        }

        return xmlString;
    }

}
