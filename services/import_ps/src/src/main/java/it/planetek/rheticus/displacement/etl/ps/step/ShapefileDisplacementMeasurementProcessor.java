package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.ps.entity.MeasureVO;
import it.planetek.rheticus.displacement.etl.ps.entity.Ps;
import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import lombok.Builder;
import lombok.Getter;
import lombok.experimental.Accessors;
import org.apache.commons.lang3.StringUtils;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.springframework.batch.item.ItemProcessor;

import java.util.*;

public class ShapefileDisplacementMeasurementProcessor implements ItemProcessor<ShapefileEntry, Ps> {

    private static final String START_NAME_COLUMNS_DISPLACEMENT = "DL";
    private static final String START_NAME_COLUMNS_AMPLITUDE = "AM";
    private static final int START_NAME_COLUMNS_DISPLACEMENT_LENGTH = START_NAME_COLUMNS_DISPLACEMENT.length();
    private static final int START_NAME_COLUMNS_AMPLITUDE_LENGTH = START_NAME_COLUMNS_AMPLITUDE.length();

    @Override
    public Ps process(ShapefileEntry shapefileEntry) {
        if (shapefileEntry == null) return null;

        SimpleFeature feature = shapefileEntry.getDisplacementSimpleFeature();
        ProcessedMeasures processedMeasures = processMeasures(feature, shapefileEntry.getAmplitudeSimpleFeature());

        Ps.PsBuilder psBuilder = Ps.builder();

        Ps ps = psBuilder
                .target(shapefileEntry.getTarget())
                .cropIdentifier(shapefileEntry.getCropIdentifier())
                .scattererCode((String) feature.getAttribute("CODE"))
                .displacementMeasures(processedMeasures.getMeasures())
                .build();

        return ps;
    }

    private ProcessedMeasures processMeasures(SimpleFeature displacementFeature, SimpleFeature amplitudeFeature) {
        List<MeasureVO> orderedMeasures = extractOrderedByDateMeasures(displacementFeature, amplitudeFeature);
        return ProcessedMeasures.builder()
                                .measures(orderedMeasures).build();
    }

    protected List<MeasureVO> extractOrderedByDateMeasures(SimpleFeature displacementFeature, SimpleFeature amplitudeFeature) {
        Collection<Property> displacementProperties = displacementFeature.getProperties();
        Map<String, MeasureVO> measuresMap = new HashMap<>(displacementProperties.size());
        for (Property property : displacementProperties) {
            String propertyName = property.getName().toString();
            if (!StringUtils.startsWithIgnoreCase(propertyName, START_NAME_COLUMNS_DISPLACEMENT)) continue;

            float value = ((Number) displacementFeature.getAttribute(propertyName)).floatValue();
            String measureDate = propertyName.substring(START_NAME_COLUMNS_DISPLACEMENT_LENGTH);
            MeasureVO measureVO = new MeasureVO(measureDate, value);
            measuresMap.put(measureDate, measureVO);
        }

        if (amplitudeFeature != null) {
            Collection<Property> amplitudeProperties = amplitudeFeature.getProperties();
            for (Property property : amplitudeProperties) {
                String propertyName = property.getName().toString();
                if (!StringUtils.startsWithIgnoreCase(propertyName, START_NAME_COLUMNS_AMPLITUDE)) continue;

                float value = ((Number) amplitudeFeature.getAttribute(propertyName)).floatValue();

                String measureDate = propertyName.substring(START_NAME_COLUMNS_AMPLITUDE_LENGTH);
                if (measuresMap.containsKey(measureDate)) {
                    MeasureVO measureVO = measuresMap.get(measureDate);
                    measureVO.setAmplitudeMeasurement(value);
                }
            }
        }

        List<MeasureVO> measures = new ArrayList<>(measuresMap.values());
        measures.sort(Comparator.comparing(MeasureVO::getDate));
        return measures;
    }

    @Getter
    @Accessors(prefix = "m")
    public static class ProcessedMeasures {
        private List<MeasureVO> mMeasures;

        @Builder
        public ProcessedMeasures(List<MeasureVO> measures) {
            mMeasures = measures;
        }
    }

}
