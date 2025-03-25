package ch.nb.persistence.connection;


import ch.nb.utils.SimpleLogger;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Manages a single database connection for the application.
 * Uses a Singleton pattern to ensure only one connection is active.
 */
public class DatabaseConnection {

    // Loads database properties from a configuration file.
    private static PropertiesLoader propertiesLoader = new PropertiesLoader("database.properties");

    private static final String DB_URL = propertiesLoader.getProperty("db.url");
    private static final String DB_USER = propertiesLoader.getProperty("db.user");
    private static final String DB_PASSWORD = propertiesLoader.getProperty("db.password");

    private static Connection connection;

    /**
     * Returns the active database connection, creating if it does not exist.
     *
     * @return the active database connection
     * @throws SQLException if connection fails
     */
    public static Connection getConnection() throws SQLException {
        if (connection == null) {
            try {
                connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                SimpleLogger.warning("[+] CONNECTION OPENED");
            } catch (SQLException e) {
                SimpleLogger.error("Failed to connect to database");
                throw new SQLException("Failed to connect to database", e);
            }
        }
        return connection;
    }

    /**
     * Closes the current database connection, if it exists, and logs the closure.
     *
     * @throws SQLException if closing the connection fails
     */
    public static void closeConnection() throws SQLException {
        if (connection != null) {
            try {
                connection.close();
                connection = null;
                SimpleLogger.warning("[-] CONNECTION CLOSED");
            } catch (SQLException e) {
                throw new SQLException("Failed to close database connection", e);
            }
        }
    }

}
