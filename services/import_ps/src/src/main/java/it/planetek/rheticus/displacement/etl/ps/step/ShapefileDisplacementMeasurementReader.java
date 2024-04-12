package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import it.planetek.rheticus.displacement.etl.util.ShapefileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;
import org.geotools.data.DataStore;
import org.geotools.data.DataStoreFinder;
import org.geotools.data.FeatureSource;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.FeatureIterator;
import org.geotools.util.URLs;
import org.json.JSONObject;
import org.json.XML;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.AfterStep;
import org.springframework.batch.core.annotation.BeforeStep;
import org.springframework.batch.item.file.ResourceAwareItemReaderItemStream;
import org.springframework.batch.item.support.AbstractItemCountingItemStreamItemReader;
import org.springframework.core.io.Resource;

import java.io.File;
import java.io.IOException;
import java.nio.BufferUnderflowException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class ShapefileDisplacementMeasurementReader
        extends AbstractItemCountingItemStreamItemReader<ShapefileEntry>
        implements ResourceAwareItemReaderItemStream<ShapefileEntry> {
    private static final Logger log;
    private static final String SEPARATOR_LINE_01;
    private static final String SEPARATOR_LINE_02;

    static {
        log = LoggerFactory.getLogger(ShapefileDisplacementMeasurementReader.class);
        SEPARATOR_LINE_01 = StringUtils.repeat("=", 30);
        SEPARATOR_LINE_02 = StringUtils.repeat("-", 30);
    }

    private String mCrop;
    private String mSensorCode;
    private String mSupermasterUid;
    private String mBeam;
    private String mCode;
    private String mTarget;

    private String mDisplacementShapefileNameWithExtension;
    private DataStore mDisplacementDataStore;
    private String mAmplitudeShapefileNameWithExtension;
    private DataStore mAmplitudeDataStore;
    private Path mProductXmlPath;

    private FeatureIterator<SimpleFeature> mDisplacementSimpleFeatureIterator;
    private FeatureIterator<SimpleFeature> mAmplitudeSimpleFeatureIterator;

    private StepExecution mStepExecution;

    public ShapefileDisplacementMeasurementReader() throws ShapefileException {
        super();
        setName("SHAPEFILE_MEASUREMENT_READER");
    }

    @Override
    public void setResource(Resource resource) {
        try {
            init(resource.getFile().getCanonicalPath());
        } catch (IOException | ShapefileException e) {
        }
    }

    private void init(final String shapefileNameWithExt) throws ShapefileException {
        mDisplacementShapefileNameWithExtension = ShapefileUtils.sanitizeShapefileName(shapefileNameWithExt);
        mAmplitudeShapefileNameWithExtension = getShapefilePath() + getDisplacementShapefileName().replace("SPINUA", "SPINUAAM");
        mCrop = ShapefileUtils.sanitizeDataset(ShapefileUtils.getDatasetFromShapefileName(shapefileNameWithExt));

        String productXmlPath = getShapefilePath() + "product.xml";
        mProductXmlPath = Paths.get(productXmlPath);
        if (mProductXmlPath == null) {
            log.error("Not found file <" + productXmlPath + ">.");
        }
    }

    @BeforeStep
    public void beforeStep(StepExecution stepExecution) {
        mStepExecution = stepExecution;
    }

    @AfterStep
    public void afterStep(StepExecution stepExecution) {
        log.info(String.format("%s completed in: %d ms",
                               stepExecution.getStepName(),
                               System.currentTimeMillis() - stepExecution.getStartTime().getTime()));
    }

    @Override
    protected void doOpen() throws Exception {
        openAndLoadProductXml();

        FeatureCollection<SimpleFeatureType, SimpleFeature> displacementCollection = openDisplacementShapefile();
        FeatureCollection<SimpleFeatureType, SimpleFeature> amplitudeCollection = openAmplitudeShapefile();

        if (displacementCollection != null) {
            log.info(getDisplacementShapefileName() + " - " + mCrop);
            mStepExecution.getExecutionContext().put("cropId", mCrop);
            mStepExecution.getExecutionContext().put("shapefileName", getDisplacementShapefileName());
        } else {
            throw new ShapefileException("Occur problem during opening shapefile " + mDisplacementShapefileNameWithExtension);
        }

        mDisplacementSimpleFeatureIterator = displacementCollection.features();
        if (amplitudeCollection != null) {
            mAmplitudeSimpleFeatureIterator = amplitudeCollection.features();
        }

        setMaxItemCount(displacementCollection.size());
    }

    @Override
    protected ShapefileEntry doRead() throws Exception {
        try {
            CropIdentifier cropIdentifier = CropIdentifier.builder()
                                                          .sensorCode(mSensorCode)
                                                          .supermasterUid(mSupermasterUid)
                                                          .beam(mBeam)
                                                          .code(mCode)
                                                          .build();

            ShapefileEntry shapefileEntry = ShapefileEntry.builder()
                                                          .cropIdentifier(cropIdentifier)
                                                          .target(ShapefileEntry.Target.getValue(mTarget))
                                                          .displacementSimpleFeature(mDisplacementSimpleFeatureIterator.next())
                                                          .amplitudeSimpleFeature(mAmplitudeSimpleFeatureIterator != null
                                                                                          ? mAmplitudeSimpleFeatureIterator.hasNext() ? mAmplitudeSimpleFeatureIterator.next() : null
                                                                                          : null)
                                                          .build();
            return shapefileEntry;
        } catch (BufferUnderflowException e) {
            log.error("Error: {}", e.getMessage());
            e.printStackTrace();
            return null;
        }

    }

    @Override
    protected void doClose() throws Exception {
        if (closeShapefiles()) {
            log.info("Close shapefiles: {}", getDisplacementShapefileName() + ", " + getAmplitudeShapefileName());
        } else {
            throw new ShapefileException("Problem during closing shapefiles: " + mDisplacementShapefileNameWithExtension + ", " + mAmplitudeShapefileNameWithExtension);
        }
    }

    public void jumpToPs(int psIndex) throws Exception {
        super.jumpToItem(psIndex);
    }

    protected FeatureCollection<SimpleFeatureType, SimpleFeature> openDisplacementShapefile() {
        File file = new File(mDisplacementShapefileNameWithExtension);

        Map<String, Object> map = new HashMap<>();
        map.put("url", URLs.fileToUrl(file));

        FeatureCollection<SimpleFeatureType, SimpleFeature> collection = null;
        try {
            mDisplacementDataStore = DataStoreFinder.getDataStore(map);
            FeatureSource<SimpleFeatureType, SimpleFeature> source = mDisplacementDataStore.getFeatureSource(mDisplacementDataStore.getTypeNames()[0]);
            collection = source.getFeatures();
        } catch (IOException e) {
            log.error("Error: {}", e.getMessage());
            e.printStackTrace();
        }
        return collection;
    }

    protected FeatureCollection<SimpleFeatureType, SimpleFeature> openAmplitudeShapefile() {
        File file = new File(mAmplitudeShapefileNameWithExtension);
        if (!file.exists() || file.isDirectory()) return null;


        Map<String, Object> map = new HashMap<>();
        map.put("url", URLs.fileToUrl(file));

        FeatureCollection<SimpleFeatureType, SimpleFeature> collection = null;
        try {
            mAmplitudeDataStore = DataStoreFinder.getDataStore(map);
            FeatureSource<SimpleFeatureType, SimpleFeature> source = mAmplitudeDataStore.getFeatureSource(mAmplitudeDataStore.getTypeNames()[0]);
            collection = source.getFeatures();
        } catch (IOException e) {
            log.error("Error: {}", e.getMessage());
            e.printStackTrace();
        }
        return collection;
    }

    protected boolean closeShapefiles() {
        if (mDisplacementSimpleFeatureIterator != null) {
            mDisplacementSimpleFeatureIterator.close();
        }
        if (mDisplacementDataStore != null) {
            mDisplacementDataStore.dispose();
        }
        if (mAmplitudeSimpleFeatureIterator != null) {
            mAmplitudeSimpleFeatureIterator.close();
        }
        if (mAmplitudeDataStore != null) {
            mAmplitudeDataStore.dispose();
        }
        return true;
    }


    protected void openAndLoadProductXml() throws IOException {
        List<String> productXmlStrings = Files.readAllLines(mProductXmlPath, StandardCharsets.UTF_8);

        JSONObject xmlJSONObj = XML.toJSONObject(String.join("", productXmlStrings));
        JSONObject processorOutputMetadataJsonObj = xmlJSONObj.getJSONObject("processor_output_metadata");
        JSONObject outputProductJsonObj = processorOutputMetadataJsonObj.getJSONObject("output_product");

        String sensorCode = "S1";
        if (!outputProductJsonObj.isNull("mission")) {
            sensorCode = outputProductJsonObj.getString("mission");
            if (sensorCode.equalsIgnoreCase("Sentinel-1")) {
                sensorCode = "S1";
            }
        }

        if (outputProductJsonObj.isNull("supermaster_id")) {
            throw new RuntimeException("Field supermaster_id not found in product.xml for crop " + mCrop);
        }
        String supermasterUid = outputProductJsonObj.getString("supermaster_id");

        if (outputProductJsonObj.isNull("swath_id") && outputProductJsonObj.isNull("beam_id")) {
            throw new RuntimeException("Field swath_id or beam_id not found in product.xml for crop " + mCrop);
        }
        String beam = !outputProductJsonObj.isNull("swath_id")
                ? outputProductJsonObj.getString("swath_id")
                : outputProductJsonObj.getString("beam_id");

        if (outputProductJsonObj.isNull("crop_id")) {
            throw new RuntimeException("Field crop_id not found in product.xml for crop " + mCrop);
        }
        String code = outputProductJsonObj.getString("crop_id");
        String target = null;
        if (!outputProductJsonObj.isNull("target")) {
            target = outputProductJsonObj.getString("target");
        }

        mSensorCode = sensorCode;
        mSupermasterUid = supermasterUid;
        mBeam = beam;
        mCode = code;
        mTarget = target;
    }

    private String getDisplacementShapefileName() {
        return FilenameUtils.getName(mDisplacementShapefileNameWithExtension);
    }

    private String getAmplitudeShapefileName() {
        return FilenameUtils.getName(mAmplitudeShapefileNameWithExtension);
    }


    private String getShapefilePath() {
        return FilenameUtils.getFullPath(mDisplacementShapefileNameWithExtension);
    }
}