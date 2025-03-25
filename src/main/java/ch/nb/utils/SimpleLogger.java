package ch.nb.utils;


import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * A simple utility class for logging messages to the console with different log levels and colored output.
 * The log levels supported are INFO, WARNING, and ERROR. Each log level has a corresponding color for better visibility.
 */
public class SimpleLogger {

    // ANSI escape codes for colored console output (because I like colors)
    // These constants are used to format the log messages with colors in the console.
    public static final String ANSI_RED = "\u001B[31m";
    public static final String ANSI_GREEN = "\u001B[32m";
    public static final String ANSI_YELLOW = "\u001B[33m";
    public static final String ANSI_BLUE = "\u001B[34m";
    public static final String ANSI_MAGENTA = "\u001B[35m";
    public static final String ANSI_CYAN = "\u001B[36m";
    public static final String ANSI_WHITE = "\u001B[37m";
    public static final String ANSI_RESET = "\u001B[0m";

    public enum LogLevel {
        INFO, WARNING, ERROR
    }

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * Logs a message with the specified log level, formatted with a timestamp and colored output.
     *
     * @param level the log level (INFO, WARNING, ERROR)
     * @param message the message to be logged
     */
    private static void log(LogLevel level, String message) {
        String timestamp = LocalDateTime.now().format(DATE_FORMAT);
        String formattedMessage = String.format("%s [%s] %s", timestamp, level, message);

        switch (level) {
            case INFO:
                System.out.println(ANSI_GREEN + formattedMessage + ANSI_RESET);
                break;
            case WARNING:
                System.out.println(ANSI_YELLOW + formattedMessage + ANSI_RESET);
                break;
            case ERROR:
                System.out.println(ANSI_RED + formattedMessage + ANSI_RESET);
                break;
            default:
                System.out.println(formattedMessage);
        }
    }

    /**
     * Logs an informational message.
     *
     * @param message the message to log
     */
    public static void info(String message) {
        log(LogLevel.INFO, message);
    }

    /**
     * Logs a warning message.
     *
     * @param message the message to log
     */
    public static void warning(String message) {
        log(LogLevel.WARNING, message);
    }

    /**
     * Logs an error message.
     *
     * @param message the message to log
     */
    public static void error(String message) {
        log(LogLevel.ERROR, message);
    }
}
