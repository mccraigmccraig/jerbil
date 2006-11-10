package jerbil.example;

/**
 * A class for testing the setting of system properties.
 */
public class Main2 {
    public static void main(String[] args) {
        if (!System.getProperty("jerbil.foo").equals("baz")) {
            throw new RuntimeException("jerbil.foo!=baz");
        }
         if (!System.getProperty("java.util.logging.config.file").equals("foo.properties")) {
            throw new RuntimeException("java.util.logging.config.file!=java.util.logging.config.file");
        }
    }
}
