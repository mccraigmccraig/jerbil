import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

/**
 * TODO: comment
 */
public class JerbilClassLoader extends ClassLoader {
  
    private static final boolean debug = Boolean.getBoolean( "jerbil.debug" );
    
    public JerbilClassLoader(ClassLoader parent) {
        super( parent );
    }

    public Class<?> findClass(String name) throws
            ClassNotFoundException {
              
        if (debug) {
          System.err.println( "findClass(" + name + ")" );
        }
        
        byte[] classBytes = findClassBytes( name );
        return defineClass( name, classBytes,
                0, classBytes.length );
    }

    private byte[] findClassBytes(String className) throws ClassNotFoundException {
        InputStream in = null;
        try
        {
            String root = System.getProperty( "build.root" );
            if ( root == null )
            {
                throw new ClassNotFoundException( "Class " + className + " not found: set build.root" );
            }
            String pathName = root +
                    File.separatorChar + className.
                    replace( '.', File.separatorChar )
                    + ".class";

            in = new FileInputStream( pathName );

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[16384];

            int c;
            while ((c = in.read( buffer )) >= 0)
            {
                out.write( buffer, 0, c );
            }
            return out.toByteArray();
        }
        catch ( IOException e )
        {
            throw new ClassNotFoundException( "Class " + className + " not found: I/O", e );
        }
        finally
        {
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
}
