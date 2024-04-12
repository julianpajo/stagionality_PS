package it.planetek.rheticus.displacement.etl.ps.step;

/**
 * The Class ShapefileException.
 */
public class ShapefileException
        extends Exception
{

    /** The Constant serialVersionUID. */
    private static final long serialVersionUID = 1L;

    /**
     * Instantiates a new shapefile exception.
     */
    public ShapefileException() {
        super();
    }

    /**
     * Instantiates a new shapefile exception.
     *
     * @param message
     *            the message
     */
    public ShapefileException(final String message) {
        super(message);
    }

    /**
     * Instantiates a new shapefile exception.
     *
     * @param message
     *            the message
     * @param cause
     *            the cause
     */
    public ShapefileException(final String message, final Throwable cause) {
        super(message, cause);
    }

    /**
     * Instantiates a new shapefile exception.
     *
     * @param cause
     *            the cause
     */
    public ShapefileException(final Throwable cause) {
        super(cause);
    }
}
