package jerbil.sample;

import org.testng.annotations.Test;
import org.testng.Assert;

@Test
public class TestJerbiliser {
    public void testAdd() {
        Jerbiliser jb = new Jerbiliser();
        Assert.assertEquals(jb.add(1, 1), 2);
    }

    public void testSubstract() {
        Jerbiliser jb = new Jerbiliser();
        Assert.assertEquals(jb.substract(10, 1), 9);
    }
}
