import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.Arrays;

/**
 * <p>A classloader which is used by the jerbil build system to dynamically
 * add classes to the running VM, after they've been built.</p>
 *
 * <p>The initial build paths must be set using the system property
 * <code>jerbil.build.root</code> (classpath-like).</p>
 */
public class JerbilClassLoader extends ClassLoader {
  
    private final boolean debug = Boolean.getBoolean( "jerbil.debug" );
    private final String[] roots;

    public JerbilClassLoader(ClassLoader parent) {
        super( parent );
        String root = System.getProperty( "jerbil.build.root" );
        if ( root == null ) {
            throw new IllegalArgumentException("Need to set system property build.root!");
        }
        roots = root.split(":");
        debug("initialised with root paths " + Arrays.asList(roots));
    }

    public Class<?> findClass(String name) throws
            ClassNotFoundException {
        debug( "findClass(" + name + ")" );
        byte[] classBytes = findClassBytes( name );
        return defineClass( name, classBytes,
                0, classBytes.length );
    }

    public InputStream getResourceAsStream(String name) {
        debug("getResourceAsStream(" + name + ")");

        File f = null;
        for (String root : roots) {
            File aFile = new File(root, name);
            if ( aFile.exists()) {
                f = aFile;
                debug("resolved to " + aFile.toString());
                break;
            }
        }

        if (f != null) {
            try {
                return new ByteArrayInputStream(readBytes(new FileInputStream(f)));
            } catch (Exception e) {/*falltrough*/}
        }

        return super.getResourceAsStream(name);
    }

    private byte[] findClassBytes(String className) throws ClassNotFoundException {
        InputStream in = null;
        try
        {
            File f = null;
            for (String root : roots) {
                String pathName = root +
                        File.separatorChar + className.
                        replace( '.', File.separatorChar )
                        + ".class";

                File aFile = new File(pathName);
                if (aFile.exists()) {
                    f = aFile;
                    debug("resolved to " + aFile.toString());
                    break;
                }
           }

            if (f == null)  {
                throw new ClassNotFoundException("Class " + className + " not found");
            }
            return readBytes(new FileInputStream(f));
        }
        catch ( IOException e )
        {
            throw new ClassNotFoundException( "Class " + className + " not found: I/O", e );
        }
    }

    private byte[] readBytes(InputStream in) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[16384];
        int c;
        try {
            while ((c = in.read( buffer )) >= 0)
            {
                out.write( buffer, 0, c );
            }
            return out.toByteArray();
        } finally {
           if ( in != null )
            {
                try
                {
                    in.close();
                } catch ( IOException e )
                {
                }
            }
        }
    }

    private void debug(String s) {
        if (debug) {
            System.err.println(getClass().getSimpleName() + ": " + s);
        }
    }
}
