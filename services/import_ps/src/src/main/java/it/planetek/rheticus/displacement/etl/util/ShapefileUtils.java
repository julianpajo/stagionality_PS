package it.planetek.rheticus.displacement.etl.util;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;

public class ShapefileUtils {

    public static String sanitizeShapefileName(final String nameOfShapefileName) {
        return StringUtils.trimToEmpty(nameOfShapefileName);
    }

    public static String getDatasetFromShapefileName(final String shapeFileNameWithExtension) {
        String dataset = StringUtils.trimToEmpty(shapeFileNameWithExtension);
        dataset = FilenameUtils.getPathNoEndSeparator(dataset);
        dataset = FilenameUtils.getBaseName(dataset);
        return dataset;
    }

    public static String sanitizeDataset(final String dataset) {
        String datasetNormalized = StringUtils.trimToEmpty(dataset);
        datasetNormalized = StringUtils.normalizeSpace(datasetNormalized);
        datasetNormalized = StringUtils.replace(datasetNormalized, " ", "_");
        datasetNormalized = StringUtils.deleteWhitespace(datasetNormalized);
        return datasetNormalized;
    }
}
