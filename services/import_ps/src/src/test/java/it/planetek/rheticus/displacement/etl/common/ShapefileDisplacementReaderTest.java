package it.planetek.rheticus.displacement.etl.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.File;

import it.planetek.rheticus.displacement.etl.ps.step.ShapefileDisplacementReader;
import it.planetek.rheticus.displacement.etl.ps.step.ShapefileException;
import org.apache.commons.lang3.StringUtils;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.item.ExecutionContext;

import it.planetek.rheticus.displacement.etl.LoggingRule;
import it.planetek.rheticus.displacement.etl.ps.entity.Ps;


// @RunWith(SpringRunner.class)
// @ActiveProfiles("batchtest")
public class ShapefileDisplacementReaderTest {
    private static final Logger log                   = LoggerFactory.getLogger(ShapefileDisplacementReaderTest.class);

    @Rule
    public LoggingRule          loggingRule           = new LoggingRule(log);

    private static final String PATH_TO_DATA_TEST     = "shapefileBase";
    private static final String SHAPEFILE_NAME        = "SPINUA1_30000.shp";
    private static final String SHAPEFILE_NAME_NO_DBF = "SPINUA1_30000-NO-DBF.shp";

    private static final String dataset               = "DATASET";

    private String              pathToDataTest;

    @Before
    public void setUp() {
        /*
         * IMPORTANTE: affinchè vengano trovati i file dei dati di test è necessario lanciare: mvn test
         * in modo che i resources test vengano spostati nella directory "." ossia target/test-class
         */

        pathToDataTest = ClassLoader.getSystemResource(".").getFile() + PATH_TO_DATA_TEST + File.separator;
    }

    /**
     * Read shapefile not present on file system raise exception.
     */
    @Test
    public void readShapefileNotPresentOnFileSystemRaiseException() {
        String shapefileName = pathToDataTest + "FileNotExist.shp";
        try {
            // new ShapefileDisplacementReader(dataset, shapefileName);
            new ShapefileDisplacementReader();
            fail("Excepted exception");
        }
        catch (ShapefileException e) {
            log.debug("Error message: {}", e.getMessage());
            assertTrue("messaggio", StringUtils.containsIgnoreCase(e.getMessage(), "non esiste"));
        }
    }

    @Test
    public void readTheNumberOfDisplacementMeasures() {
        String shapefileName = pathToDataTest + SHAPEFILE_NAME;

        try {
            ShapefileDisplacementReader shpReader = new ShapefileDisplacementReader(shapefileName);
            shpReader.setName("TEST");
            ExecutionContext executionContext = new ExecutionContext();
            shpReader.open(executionContext);

//            assertThat(shpReader.countDisplacementMeasures()).isEqualTo(132);
        }
        catch (ShapefileException e) {
            fail("Unexcepted exception");
        }
    }

    @Test
    public void jump_to_ps_out_of_the_bound() {
        String shapefileName = pathToDataTest + SHAPEFILE_NAME;
        ShapefileDisplacementReader shpReader = null;
        try {
            shpReader = new ShapefileDisplacementReader(shapefileName);
            shpReader.open(new ExecutionContext());
            shpReader.setName("TEST");
            shpReader.jumpToPs(9999);
//            Ps psUnderTest = shpReader.read();
//            assertThat(psUnderTest).isNull();
        }
        catch (Exception e) {
            log.error(e.getMessage());
            e.printStackTrace();
        }

    }

    @Test
    public void read_ps_number_0() {
        String shapefileName = pathToDataTest + SHAPEFILE_NAME;
        Ps psUnderTest = null;
        ShapefileDisplacementReader shpReader = null;
        try {
            shpReader = new ShapefileDisplacementReader(shapefileName);
            shpReader.open(new ExecutionContext());
            shpReader.setName("TEST");
//            psUnderTest = shpReader.read();
        }
        catch (Exception e) {
            log.error(e.getMessage());
            fail("Unexcepted exception");
        }

        assertThat(psUnderTest).isNotNull();
        // log.trace(psUnderTest.toString());
//        log.trace("shpReader.getCurrentItemCount={}", shpReader.getCurrentItemCount());

        boolean checkPsUnderTest = checkPs(psUnderTest, "L08791P07686", 14.34725, 36.994625, -4.0, 36.0, 7.8, -11.5, 0.54, 43.755, 157.895, -0.5, 0.63);
        assertTrue("Check ps[0] failed", checkPsUnderTest);
        String dateDisplacementMeasure = "20141013";
        boolean checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, 0);
        assertTrue("Check ps[0] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20150517";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, 14.1);
        assertTrue("Check ps[0] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20180107";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, -0.4);
        assertTrue("Check ps[0] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
    }

    @Test
    public void read_ps_number_49() {
        String shapefileName = pathToDataTest + SHAPEFILE_NAME;
        Ps psUnderTest = null;
        ShapefileDisplacementReader shpReader = null;
        try {
            shpReader = new ShapefileDisplacementReader(shapefileName);
            shpReader.open(new ExecutionContext());
            shpReader.setName("TEST");
            shpReader.jumpToPs(49);
//            psUnderTest = shpReader.read();
        }
        catch (Exception e) {
            log.error(e.getMessage());
            fail("Unexcepted exception");
        }

        assertThat(psUnderTest).isNotNull();
        // log.trace(psUnderTest.toString());
//        log.trace("shpReader.getCurrentItemCount={}", shpReader.getCurrentItemCount());

        boolean checkPsUnderTest = checkPs(psUnderTest, "L08808P07704", 14.347681, 36.996843, 12.1, 52.0, 3.7, 0.5, 0.79, 43.762, 157.874, -0.5, 0.30);
        assertTrue("Check ps[49] failed", checkPsUnderTest);
        String dateDisplacementMeasure = "20141013";
        boolean checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, 0);
        assertTrue("Check ps[49] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20150517";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, -4.2);
        assertTrue("Check ps[49] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20180107";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, 3.8);
        assertTrue("Check ps[49] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
    }

    @Test
    public void read_ps_number_99() {
        String shapefileName = pathToDataTest + SHAPEFILE_NAME;
        Ps psUnderTest = null;
        ShapefileDisplacementReader shpReader = null;
        try {
            shpReader = new ShapefileDisplacementReader(shapefileName);
            shpReader.open(new ExecutionContext());
            shpReader.setName("TEST");
            shpReader.jumpToPs(99);
//            psUnderTest = shpReader.read();
        }
        catch (Exception e) {
            log.error(e.getMessage());
            fail("Unexcepted exception");
        }

        assertThat(psUnderTest).isNotNull();
        // log.trace(psUnderTest.toString());
//        log.trace("shpReader.getCurrentItemCount={}", shpReader.getCurrentItemCount());

        boolean checkPsUnderTest = checkPs(psUnderTest, "L08812P07718", 14.348114, 36.997411, 12.8, 52.7, 9.2, -1.0, 0.55, 43.765, 157.870, 0.0, 0.75);
        assertTrue("Check ps[99] failed", checkPsUnderTest);
        String dateDisplacementMeasure = "20141013";
        boolean checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, 0);
        assertTrue("Check ps[99] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20150517";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, -4.4);
        assertTrue("Check ps[99] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
        dateDisplacementMeasure = "20180107";
        checkDisplacementMeasure = checkDisplacementMeasure(psUnderTest, dateDisplacementMeasure, -8.3);
        assertTrue("Check ps[99] displacement " + dateDisplacementMeasure + " failed", checkDisplacementMeasure);
    }

    private boolean checkPs(Ps psUnderTest,
                            String psId,
                            double lat,
                            double lng,
                            double hGeo,
                            double hEll,
                            double hStdDev,
                            double hAuxDem,
                            double coh,
                            double incAng,
                            double headAng,
                            double vLos,
                            double vLosStdDev)
    {
        final double EPSILON = 0.00001;

        boolean isEqual = true;
        isEqual = isEqual && StringUtils.equalsIgnoreCase(psUnderTest.getDatasetName(), dataset);
        isEqual = isEqual && StringUtils.equalsIgnoreCase(psUnderTest.getPsId(), psId);
        isEqual = isEqual && equalsNumber(psUnderTest.getLatitude(), lat, EPSILON);
        isEqual = isEqual && equalsNumber(psUnderTest.getLongitude(), lng, EPSILON);
        isEqual = isEqual && equalsNumber(psUnderTest.getHeight(), hGeo, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getHGeo(), hGeo, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getHEll(), hEll, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getHStdDev(), hStdDev, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getHAuxDem(), hAuxDem, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getCoh(), coh, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getIncAng(), incAng, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getHeadAng(), headAng, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getVLos(), vLos, EPSILON);
        // isEqual = isEqual && equalsNumber(psUnderTest.getVLosStdDev(), vLosStdDev, EPSILON);

        return isEqual;
    }

    private boolean checkDisplacementMeasure(final Ps psUnderTest, final String dateDisplacementMeasure, final double displacementMeasureTarget) {
        final double EPSILON = 0.00001;

        return equalsNumber(psUnderTest.getDisplacementMeasure(dateDisplacementMeasure), displacementMeasureTarget, EPSILON);
    }

    private boolean equalsNumber(double a, double b, double eps) {
        if (a == b)
            return true;
        return Math.abs(a - b) < eps;
    }

    private boolean equalsNumber(double a, double b) {
        final double EPSILON = 0.0000001;
        if (a == b)
            return true;
        return Math.abs(a - b) < EPSILON * Math.max(Math.abs(a), Math.abs(b));
    }
}
