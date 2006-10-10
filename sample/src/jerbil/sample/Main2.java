package jerbil.sample;

/**
 * TODO: comment
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
