package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import it.planetek.rheticus.displacement.etl.util.ShapefileUtils;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FilenameUtils;
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
import org.springframework.batch.core.StepExecution;
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

@Slf4j
public class ScattererReader
        extends AbstractItemCountingItemStreamItemReader<ShapefileEntry>
        implements ResourceAwareItemReaderItemStream<ShapefileEntry> {

    private String mDisplacementShapefileNameWithExtension;
    private DataStore mDisplacementDataStore;
    private FeatureIterator<SimpleFeature> mDisplacementSimpleFeatureIterator;
    private StepExecution mStepExecution;
    private String mCrop;
    private String mSensorCode;
    private String mSupermasterUid;
    private String mBeam;
    private String mCode;

    private Path mProductXmlPath;

    public ScattererReader() {

        super();
        this.setName("SCATTERER_READER");
    }

    @Override
    public void setResource(Resource resource) {
        try {
            init(resource.getFile().getCanonicalPath());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void init(final String shapefileNameWithExt) {
        mDisplacementShapefileNameWithExtension = ShapefileUtils.sanitizeShapefileName(shapefileNameWithExt);
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

    @Override
    protected void doOpen() throws Exception {
        openAndLoadProductXml();

        FeatureCollection<SimpleFeatureType, SimpleFeature> displacementCollection = openDisplacementShapefile();

        if (displacementCollection != null) {
            log.info(getDisplacementShapefileName() + " - " + mCrop);
            mStepExecution.getExecutionContext().put("cropId", mCrop);
            mStepExecution.getExecutionContext().put("shapefileName", getDisplacementShapefileName());
        } else {
            throw new ShapefileException("Occur problem during opening shapefile " + mDisplacementShapefileNameWithExtension);
        }

        mDisplacementSimpleFeatureIterator = displacementCollection.features();
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
                                                          .displacementSimpleFeature(mDisplacementSimpleFeatureIterator.next())
                                                          .build();
            return shapefileEntry;
        } catch (BufferUnderflowException e) {
            log.error(e.getMessage());
            return null;
        }
    }

    @Override
    protected void doClose() throws Exception {
        if (closeShapefiles()) {
            log.info("Close shapefile: {}", getDisplacementShapefileName());
        } else {
            throw new ShapefileException("Problem during closing shapefile: " + mDisplacementShapefileNameWithExtension);
        }
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

        mSensorCode = sensorCode;
        mSupermasterUid = supermasterUid;
        mBeam = beam;
        mCode = code;
    }

    protected boolean closeShapefiles() {
        if (mDisplacementSimpleFeatureIterator != null) {
            mDisplacementSimpleFeatureIterator.close();
        }
        if (mDisplacementDataStore != null) {
            mDisplacementDataStore.dispose();
        }
        return true;
    }

    private String getDisplacementShapefileName() {
        return FilenameUtils.getName(mDisplacementShapefileNameWithExtension);
    }

    private String getShapefilePath() {
        return FilenameUtils.getFullPath(mDisplacementShapefileNameWithExtension);
    }

}