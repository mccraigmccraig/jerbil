package jerbil.sample;

import static org.testng.Assert.assertEquals;
import org.testng.annotations.Test;

@Test
public class TestJerbiliser {
    public void testAdd() {
        Jerbiliser jb = new Jerbiliser();
        assertEquals(jb.add(1, 1), 2);
    }

    public void testSubstract() {
        Jerbiliser jb = new Jerbiliser();
        assertEquals(jb.substract(10, 1), 9);
    }
}
