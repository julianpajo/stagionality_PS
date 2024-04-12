package it.planetek.rheticus.displacement.etl.ps.step;

import com.sun.org.apache.xpath.internal.operations.Bool;
import com.vividsolutions.jts.geom.Point;
import it.planetek.rheticus.displacement.etl.ps.entity.*;
import lombok.Builder;
import lombok.Getter;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.math3.stat.regression.SimpleRegression;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.springframework.batch.item.ItemProcessor;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

import static java.time.temporal.ChronoUnit.DAYS;


@Slf4j
public class ShapefileDisplacementProcessor implements ItemProcessor<ShapefileEntry, Ps> {
    private static final String START_NAME_COLUMNS_DISPLACEMENT = "DL";
    private static final int START_NAME_COLUMNS_DISPLACEMENT_LENGTH = START_NAME_COLUMNS_DISPLACEMENT.length();

    @Override
    public Ps process(ShapefileEntry shapefileEntry) {
        if (shapefileEntry == null) return null;

        SimpleFeature feature = shapefileEntry.getDisplacementSimpleFeature();

        List<MeasureVO> orderedByDateMeasurement = extractOrderedByDateMeasures(feature);

        // read parameters from feature
        Number acceleration = (Number) feature.getAttribute("ACL_LOS");
        Number velocity = (Number) feature.getAttribute("V_LOS");
        Number velocityStd = (Number) feature.getAttribute("V_LOS_STD");
        Number incidenceAngle = (Number) feature.getAttribute("INC_ANG");
        Number directionAngle = (Number) feature.getAttribute("LOS_AZ_ANG");
        Number seasonalityComponent = (Number) feature.getAttribute("SEA_LOS");
        Number displacementMeanStd = (Number) feature.getAttribute("D_STD_LOS");
        Number updateFlag = (Number) feature.getAttribute("UPDT_FLAG");

        // caculate acceleration if it's null
        if(acceleration == null){
            ProcessedMeasures processedMeasures = processMeasures(orderedByDateMeasurement,
                    orderedByDateMeasurement.get(0).getDate(),
                    orderedByDateMeasurement.get(orderedByDateMeasurement.size() - 1).getDate(),
                    false);
            acceleration = processedMeasures.getAcceleration();
        }

        // check if null values and build psPeriodicPropertiesGlobal
        PsPeriodicPropertiesGlobal.PsPeriodicPropertiesGlobalBuilder psPeriodicPropertiesGlobalBuilder =
                PsPeriodicPropertiesGlobal.builder();
        if(acceleration != null){
            psPeriodicPropertiesGlobalBuilder.acceleration(acceleration.floatValue());
        }
        if(velocity != null){
            psPeriodicPropertiesGlobalBuilder.velocity(velocity.floatValue());
        }
        if(velocityStd != null){
            psPeriodicPropertiesGlobalBuilder.velocityStd(velocityStd.floatValue());
        }
        if(incidenceAngle != null){
            psPeriodicPropertiesGlobalBuilder.incidenceAngle(incidenceAngle.floatValue());
        }
        if(directionAngle != null){
            psPeriodicPropertiesGlobalBuilder.directionAngle(directionAngle.floatValue());
        }
        if(seasonalityComponent != null){
            psPeriodicPropertiesGlobalBuilder.seasonalityComponent(seasonalityComponent.floatValue());
        }
        if(displacementMeanStd != null){
            psPeriodicPropertiesGlobalBuilder.displacementMeanStd(displacementMeanStd.floatValue());
        }
        if(updateFlag != null){
            psPeriodicPropertiesGlobalBuilder.updateFlag(updateFlag.floatValue());
        }
        PsPeriodicPropertiesGlobal psPeriodicPropertiesGlobal = psPeriodicPropertiesGlobalBuilder.build();

        // read parameters from feature
        Number velocityLastYear = (Number) feature.getAttribute("VELR_L_M");
        Number velocityLastYearStandardDeviation = (Number) feature.getAttribute("VELR_STD_M");
        Number velocityLastYearLin = (Number) feature.getAttribute("VR_L_LIN");
        Number velocityLastYearLinStandardDeviation = (Number) feature.getAttribute("VR_STD_LIN");
        Number velocityLastYearCoherence = (Number) feature.getAttribute("COHR_L_M");

        // calculate last year velocity if feature velocity is null
        LocalDate lastYear = LocalDate.from(orderedByDateMeasurement.get(orderedByDateMeasurement.size() - 1).getDate()).minusDays(365);
        ProcessedMeasures processedMeasures = processMeasures(orderedByDateMeasurement,
                lastYear,
                orderedByDateMeasurement.get(orderedByDateMeasurement.size() - 1).getDate(),
                velocityLastYear == null);

        PsPeriodicPropertiesLastYear.PsPeriodicPropertiesLastYearBuilder psPeriodicPropertiesLastYearBuilder =
                PsPeriodicPropertiesLastYear.builder();
        if(processedMeasures.getAcceleration() != null){
            psPeriodicPropertiesLastYearBuilder.acceleration(processedMeasures.getAcceleration());
        }
        if(velocityLastYear != null){
            psPeriodicPropertiesLastYearBuilder.velocity(velocityLastYear.floatValue());
        }
        if(velocityLastYearStandardDeviation != null){
            psPeriodicPropertiesLastYearBuilder.velocityStandardDeviation(velocityLastYearStandardDeviation.floatValue());
        }
        if(velocityLastYearLin != null){
            psPeriodicPropertiesLastYearBuilder.velocityLin(velocityLastYearLin.floatValue());
        }
        if(velocityLastYearLinStandardDeviation != null){
            psPeriodicPropertiesLastYearBuilder.velocityLinStandardDeviation(velocityLastYearLinStandardDeviation.floatValue());
        }
        if(velocityLastYearCoherence != null){
            psPeriodicPropertiesLastYearBuilder.velocityCoherence(velocityLastYearCoherence.floatValue());
        }
        PsPeriodicPropertiesLastYear psPeriodicPropertiesLastYear = psPeriodicPropertiesLastYearBuilder.build();

        final Point coord = (Point) feature.getAttribute("the_geom");

        Number height = (Number) feature.getAttribute("H_GEO");
        if (height == null) {
            height = (Number) feature.getAttribute("GEO_HEI");
            if (height == null) {
                height = (Number) feature.getAttribute("HEIGHT");
            }
        }

        PsPeriodicProperties psPeriodicProperties = PsPeriodicProperties.builder()
                                                                        .global(psPeriodicPropertiesGlobal)
                                                                        .lastYear(psPeriodicPropertiesLastYear)
                                                                        .build();

        return Ps.builder()
                 .target(shapefileEntry.getTarget())
                 .cropIdentifier(shapefileEntry.getCropIdentifier())
                 .cornerReflectorId((Integer) feature.getAttribute("CR_ID"))
                 .scattererCode((String) feature.getAttribute("CODE"))
                 .lat(coord.getY())
                 .lng(coord.getX())
                 .height(height.floatValue())
                 .coh(((Number) feature.getAttribute("COH")).floatValue())
                 .displacementMeasures(orderedByDateMeasurement)
                 .psPeriodicProperties(psPeriodicProperties)
                 .build();
    }

    private ProcessedMeasures processMeasures(SimpleFeature feature,
                                              LocalDate startDate, LocalDate endDate) {
        List<MeasureVO> orderedMeasures = extractOrderedByDateMeasures(feature);

        return processMeasures(orderedMeasures, startDate, endDate, true);
    }

    private ProcessedMeasures processMeasures(List<MeasureVO> orderedMeasurement,
                                              LocalDate startDate, LocalDate endDate, boolean calculateVelocity) {

        Float acceleration = calculateAverageAcceleration(orderedMeasurement, startDate, endDate);
        Float velocity = null;
        if (calculateVelocity) {
            velocity = calculateAverageVelocity(orderedMeasurement, startDate, endDate);
        }

        return ProcessedMeasures.builder()
                                .acceleration(acceleration)
                                .velocity(velocity)
                                .measures(orderedMeasurement)
                                .build();
    }

    private List<MeasureVO> extractOrderedByDateMeasures(SimpleFeature feature) {
        Collection<Property> properties = feature.getProperties();
        List<MeasureVO> measures = new ArrayList<>(properties.size());
        for (Property property : properties) {
            String propertyName = property.getName().toString();
            if (!StringUtils.startsWithIgnoreCase(propertyName, START_NAME_COLUMNS_DISPLACEMENT)) continue;

            float value = ((Number) feature.getAttribute(propertyName)).floatValue();
            MeasureVO measureVO = new MeasureVO(propertyName.substring(START_NAME_COLUMNS_DISPLACEMENT_LENGTH), value);
            measures.add(measureVO);
        }

        measures.sort(Comparator.comparing(MeasureVO::getDate));
        return measures;
    }

    private Float calculateAverageAcceleration(List<MeasureVO> orderedDisplacementMeasurementList,
                                               LocalDate startDate, LocalDate endDate) {
        long daysBetweenPeriod = DAYS.between(startDate, endDate);
        long minDaysBetweenDates = 365;

        List<Period> periods = new ArrayList<>();
        int i = 0;
        while (daysBetweenPeriod - (minDaysBetweenDates * i) >= 365) {
            LocalDate periodStartDate = endDate.minusYears(i + 1);
            LocalDate periodEndDate = periodStartDate.plusYears(1);
            Period period = new Period(periodStartDate, periodEndDate);
            periods.add(period);
            i++;
        }

        if (periods.size() == 1) {
            LocalDate periodStartDate = endDate.minusYears(2);
            LocalDate periodEndDate = periodStartDate.plusYears(1);
            Period period = new Period(periodStartDate, periodEndDate);
            periods.add(period);
        }

        List<Float> velocityList = new ArrayList<>();
        for (Period period : periods) {
            List<MeasureVO> filteredMeasurementList = orderedDisplacementMeasurementList.stream()
                                                                                        .filter(m -> m.getDate().isEqual(period.getStartDate())
                                                                                                || (m.getDate().isAfter(period.getStartDate()) && m.getDate().isBefore(period.getEndDate())))
                                                                                        .collect(Collectors.toList());
            try {
                float velocity = calculateAverageVelocity(filteredMeasurementList);
                velocityList.add(velocity);
            } catch (EmptyMeasurementException e) {
                continue;
            }

        }


        Float minVelocity = velocityList.isEmpty() ? 0f : Collections.min(velocityList);
        Float maxVelocity = velocityList.isEmpty() ? 0f : Collections.max(velocityList);

        return maxVelocity - minVelocity;
    }

    private Float calculateAverageVelocity(List<MeasureVO> orderedDisplacementMeasurementList,
                                           LocalDate startDate, LocalDate endDate) {
        List<MeasureVO> filteredMeasurementList = orderedDisplacementMeasurementList.stream()
                                                                                    .filter(m -> m.getDate().isEqual(startDate)
                                                                                            || (m.getDate().isAfter(startDate) && m.getDate().isBefore(endDate)))
                                                                                    .collect(Collectors.toList());

        try {
            return calculateAverageVelocity(filteredMeasurementList);
        } catch (EmptyMeasurementException e) {
            return null;
        }
    }

    private float calculateAverageVelocity(List<MeasureVO> orderedDisplacementMeasurementList) throws EmptyMeasurementException {
        if (orderedDisplacementMeasurementList.isEmpty()) throw new EmptyMeasurementException();

        MeasureVO firstMeasure = orderedDisplacementMeasurementList.get(0);
        double[][] data = new double[orderedDisplacementMeasurementList.size()][2];

        if (orderedDisplacementMeasurementList.size() == 1) {
            return firstMeasure.getDisplacementMeasurement();
        } else {
            for (int i = 0; i < orderedDisplacementMeasurementList.size(); i++) {
                MeasureVO m = orderedDisplacementMeasurementList.get(i);
                long index = DAYS.between(firstMeasure.getDate(), m.getDate());
                data[i][0] = index;
                data[i][1] = m.getDisplacementMeasurement();

            }
            SimpleRegression simpleRegression = new SimpleRegression(true);
            simpleRegression.addData(data);

            return (float) simpleRegression.getSlope() * 365;
        }
    }

    @Getter
    @Accessors(prefix = "m")
    public static class ProcessedMeasures {
        private final Float mVelocity;
        private final Float mAcceleration;
        private final List<MeasureVO> mMeasures;

        @Builder
        public ProcessedMeasures(Float velocity, Float acceleration, List<MeasureVO> measures) {
            mVelocity = velocity;
            mAcceleration = acceleration;
            mMeasures = measures;
        }
    }
}
