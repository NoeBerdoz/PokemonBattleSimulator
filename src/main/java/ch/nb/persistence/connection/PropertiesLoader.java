package ch.nb.persistence.connection;


import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

/**
 * Loads and provides access to properties from a specified properties file.
 * Throws runtime exceptions for missing or unreadable properties.
 */
public class PropertiesLoader {

    private Properties properties;

    /**
     * Initializes the PropertiesLoader with the specified file path and loads properties.
     *
     * @param filePath the path to the properties file
     * @throws RuntimeException if the properties file cannot be loaded
     */
    public PropertiesLoader(String filePath) {
        properties = new Properties();
        try (FileInputStream file = new FileInputStream(filePath)) {
            properties.load(file);
        } catch (IOException error) {
            System.err.println("[-] Failed to load properties file: " + filePath);
            throw new RuntimeException("Properties file loading error: " + error.getMessage());        }
    }

    /**
     * Retrieves the value for the specified property key.
     *
     * @param key the property key to retrieve
     * @return the value associated with the key
     * @throws RuntimeException if the property is missing
     */
    public String getProperty(String key) {
        String value = properties.getProperty(key);
        if (value == null) {
            System.err.println("[-] Missing property: " + key);
            throw new RuntimeException("Missing required property: " + key);
        }
        return value;
    }
}