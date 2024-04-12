package it.planetek.rheticus.displacement.etl.dataset.step;

import it.planetek.rheticus.displacement.etl.dataset.entity.Dataset;
import it.planetek.rheticus.displacement.etl.util.ShapefileUtils;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.json.XML;
import org.springframework.batch.item.file.ResourceAwareItemReaderItemStream;
import org.springframework.batch.item.support.AbstractItemCountingItemStreamItemReader;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;


@Slf4j
public class Reader extends AbstractItemCountingItemStreamItemReader<Dataset>
        implements ResourceAwareItemReaderItemStream<Dataset> {

    private Path mPath;
    private String mCrop;
    private List<String> mStrings;

    public Reader() {
        setName("DATASET");
    }

    @Override
    protected Dataset doRead() throws Exception {
        JSONObject xmlJSONObj = XML.toJSONObject(String.join("", mStrings));
        JSONObject processorOutputMetadataJsonObj = xmlJSONObj.getJSONObject("processor_output_metadata");
        JSONObject outputProductJsonObj = processorOutputMetadataJsonObj.getJSONObject("output_product");

        String datasetName = "";
        if (!outputProductJsonObj.isNull("dataset_id")) {
            datasetName = outputProductJsonObj.getString("dataset_id");
        }

        String sensorCode = "S1";
        if (!outputProductJsonObj.isNull("mission")) {
            sensorCode = outputProductJsonObj.getString("mission");
            if(sensorCode.equalsIgnoreCase("Sentinel-1")) {
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

        Dataset dataset = Dataset.builder()
                                 .supermasterUid(supermasterUid)
                                 .sensorCode(sensorCode)
                                 .beam(beam)
                                 .datasetName(datasetName)
                                 .build();
        return dataset;
    }

    @Override
    protected void doOpen() throws Exception {
        mStrings = Files.readAllLines(mPath, StandardCharsets.UTF_8);
        setMaxItemCount(1);
    }

    @Override
    protected void doClose() throws Exception {
        mStrings = null;
    }

    @Override
    public void setResource(Resource resource) {
        if (resource != null) {
            String filePath = "";
            try {
                filePath = resource.getFile().getCanonicalPath();
                mPath = Paths.get(filePath);
                mCrop = ShapefileUtils.sanitizeDataset(ShapefileUtils.getDatasetFromShapefileName(filePath));
            } catch (IOException e) {
                log.error("Not found file <" + filePath + ">.");
            }
        }
    }
}