package it.planetek.rheticus.displacement.etl.ps.entity;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.annotations.SerializedName;
import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.ToString;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.math3.util.Precision;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;


@Getter
@EqualsAndHashCode
@ToString
@Slf4j
@Accessors(prefix = "m")
public class Ps {
    private static final int PRECISION = 4;
    private static final int PRECISION_COORD = 6;

    private static final int GEOHASH_NUM_OF_CHARS = 12;
    private static final int RANDOM_MAX_VALUE = 500;

    private static final String ISO_8601 = "yyyy-MM-dd'T'HH:mm:ssZ";

    private final Integer mCornerReflectorId;

    @NotNull
    private final String mScattererCode;

    @Min(value = -90)
    @Max(value = 90)
    private final double mLatitude;

    @Min(value = -180)
    @Max(value = 180)
    private final double mLongitude;

    @Min(value = -100)
    @Max(value = 8000)
    private final float mHeight;

    private final float mCoherence;

    private final PsPeriodicProperties mPsPeriodicProperties;
    private String mPsPeriodicPropertiesString;

    private String mDisplacementMeasuresString;
    private final transient List<MeasureVO> mDisplacementMeasures;

    private final CropIdentifier mCropIdentifier;

    private final ShapefileEntry.Target mTarget;

    private final transient Gson mGson;

    @Builder
    public Ps(CropIdentifier cropIdentifier,
              Integer cornerReflectorId,
              String scattererCode,
              double lat,
              double lng,
              float height,
              float coh,
              PsPeriodicProperties psPeriodicProperties,
              List<MeasureVO> displacementMeasures,
              ShapefileEntry.Target target) {
        super();
        mCropIdentifier = cropIdentifier;
        mCornerReflectorId = cornerReflectorId;
        mScattererCode = scattererCode;
        mLatitude = Precision.round(lat, PRECISION_COORD);
        mLongitude = Precision.round(lng, PRECISION_COORD);
        mHeight = Precision.round(height, PRECISION);
        mCoherence = Precision.round(coh, PRECISION);

        mPsPeriodicProperties = psPeriodicProperties;
        mDisplacementMeasures = displacementMeasures;
        mTarget = target;

        mGson = new GsonBuilder()
                .serializeNulls()
                .disableHtmlEscaping()
                .registerTypeAdapter(LocalDate.class, new MeasureVO.LocalDateAdapter())
                .create();
    }

    public String getPeriodicPropertiesString() {
        if (mPsPeriodicPropertiesString == null) {
            mPsPeriodicPropertiesString = mGson.toJson(mPsPeriodicProperties);
        }
        return mPsPeriodicPropertiesString;
    }


    public String getDisplacementMeasuresString() {
        if (mDisplacementMeasuresString == null) {
            List<LocalDate> measurementDates = new ArrayList<>(mDisplacementMeasures.size());
            List<Float> measurementValues = new ArrayList<>(mDisplacementMeasures.size());
            List<Float> amplitudeValues = new ArrayList<>(mDisplacementMeasures.size());

            for (MeasureVO displacementMeasure : mDisplacementMeasures) {
                measurementDates.add(displacementMeasure.getDate());
                measurementValues.add(displacementMeasure.getDisplacementMeasurement());
                amplitudeValues.add(displacementMeasure.getAmplitudeMeasurement());
            }
            OptimizedMeasurement optimizedMeasurement = OptimizedMeasurement.builder()
                                                                            .measurementDates(measurementDates)
                                                                            .measurementValues(measurementValues)
                                                                            .amplitudeValues(amplitudeValues)
                                                                            .build();
            mDisplacementMeasuresString = mGson.toJson(optimizedMeasurement);
        }
        return mDisplacementMeasuresString;
    }

    @Getter
    @EqualsAndHashCode
    @ToString
    @Slf4j
    @Accessors(prefix = "m")
    public static class OptimizedMeasurement {

        @SerializedName("d")
        private List<LocalDate> mMeasurementDates;
        @SerializedName("m")
        private List<Float> mMeasurementValues;
        @SerializedName("a")
        private List<Float> mAmplitudeValues;

        @Builder
        public OptimizedMeasurement(List<LocalDate> measurementDates, List<Float> measurementValues, List<Float> amplitudeValues) {
            super();
            this.mMeasurementDates = measurementDates;
            this.mMeasurementValues = measurementValues;
            this.mAmplitudeValues = amplitudeValues;
        }
    }
}
