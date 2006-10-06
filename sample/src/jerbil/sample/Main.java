package jerbil.sample;

/**
 * A main class, for testing.
 */
public class Main {
    public static void main(String[] args) {
        if (args.length == 0)
            throw new IllegalArgumentException("Main <arg1..argn>");

        Jerbiliser j = new Jerbiliser();
        int sum = 0;
        for (String a : args) {
            sum = j.add(Integer.parseInt(a), sum);
        }

        System.exit(sum == 100 ? 0 : 1);
    }
}
