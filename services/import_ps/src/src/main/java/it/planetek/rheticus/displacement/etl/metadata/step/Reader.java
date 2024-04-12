package it.planetek.rheticus.displacement.etl.metadata.step;

import it.planetek.rheticus.displacement.etl.metadata.entity.Metadata;
import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import it.planetek.rheticus.displacement.etl.util.ShapefileUtils;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONException;
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
import java.util.regex.Matcher;
import java.util.regex.Pattern;


@Slf4j
public class Reader extends AbstractItemCountingItemStreamItemReader<Metadata>
        implements ResourceAwareItemReaderItemStream<Metadata> {

    private Path mPath;
    private String mCrop;
    private List<String> mStrings;

    public Reader() {
        setName("METADATA");
    }

    @Override
    protected Metadata doRead() throws Exception {
        JSONObject xmlJSONObj = XML.toJSONObject(String.join("", mStrings));
        JSONObject processorOutputMetadataJsonObj = xmlJSONObj.getJSONObject("processor_output_metadata");
        JSONObject parametersJsonObj = processorOutputMetadataJsonObj.getJSONObject("parameters");
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

        String pass;
        try {
            pass = outputProductJsonObj.getString("pass").substring(0, 1);
        } catch (JSONException e) {
            pass = "";
        }

        double cohSuggested = parametersJsonObj.getDouble("SPEA_IICth");
        double cohMin = parametersJsonObj.getDouble("product_IICth");

        if (outputProductJsonObj.isNull("crop_geo_id")) {
            throw new RuntimeException("Field crop_geo_id not found in product.xml for crop " + mCrop);
        }
        String cropGeoId = outputProductJsonObj.getString("crop_geo_id");

        String target = null;
        if (!outputProductJsonObj.isNull("target")) {
            target = outputProductJsonObj.getString("target");
        }

        Pattern patternLat = Pattern.compile(".*LAT(-*\\d*\\.\\d*)_(-*\\d*\\.\\d*).*");
        Pattern patternLon = Pattern.compile(".*LON(-*\\d*\\.\\d*)_(-*\\d*\\.\\d*).*");

        Matcher matcherLat = patternLat.matcher(cropGeoId);
        boolean matchesLat = matcherLat.matches();
        if (!matchesLat || matcherLat.groupCount() != 2) {
            throw new RuntimeException("Field crop_geo_id found in product.xml with wrong format " + mCrop);
        }

        Matcher matcherLon = patternLon.matcher(cropGeoId);
        boolean matchesLon = matcherLon.matches();
        if (!matchesLon || matcherLon.groupCount() != 2) {
            throw new RuntimeException("Field crop_geo_id found in product.xml with wrong format " + mCrop);
        }

        double minLat = Double.parseDouble(matcherLat.group(1));
        double maxLat = Double.parseDouble(matcherLat.group(2));
        double minLon = Double.parseDouble(matcherLon.group(1));
        double maxLon = Double.parseDouble(matcherLon.group(2));

        Metadata metadata = Metadata.builder()
                                    .target(ShapefileEntry.Target.getValue(target))
                                    .sensorCode(sensorCode)
                                    .supermasterUid(supermasterUid)
                                    .beam(beam)
                                    .code(code)
                                    .metadata(xmlJSONObj.toString())
                                    .pass(pass)
                                    .cohSuggested(cohSuggested)
                                    .cohMin(cohMin)
                                    .minLat(minLat)
                                    .maxLat(maxLat)
                                    .minLon(minLon)
                                    .maxLon(maxLon)
                                    .build();
        return metadata;
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