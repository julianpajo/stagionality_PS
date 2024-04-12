package it.planetek.rheticus.displacement.etl.ps.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializationContext;
import com.google.gson.JsonSerializer;
import com.google.gson.annotations.SerializedName;
import it.planetek.rheticus.displacement.etl.util.MathUtils;
import lombok.NonNull;
import lombok.experimental.Accessors;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Type;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.Objects;


/**
 * value object that represent the acquisition date and value of a displacement measure
 */
@Accessors(prefix = "m")
public class MeasureVO implements MathUtils.SupportLinearRegression {
    private static final Logger log = LoggerFactory.getLogger(MeasureVO.class);
    private static final String PATTERN_FORMAT_DATE_YYYY_MM_DD = "yyyy-MM-dd";

    private static DateTimeFormatter mDateTimeFormatter = new DateTimeFormatterBuilder()
            .appendPattern("[uuuuMMdd]")
            .appendPattern("[uuuu/MM/dd]")
            .appendPattern("[uuuu-MM-dd]")
            .toFormatter();

    @SerializedName("d")
    private LocalDate mDate;

    @SerializedName("m")
    private float mDisplacementMeasurement;

    @SerializedName("a")
    private float mAmplitudeMeasurement;

    public MeasureVO() {
    }

    public MeasureVO(final LocalDate date, final float displacementMeasurement) {
        super();
        this.mDate = date;
        this.mDisplacementMeasurement = displacementMeasurement;
    }

    public MeasureVO(final String date, final float measure) {
        this(parseSingleDate(date), measure);
    }

    @JsonCreator
    public MeasureVO(@JsonProperty("date") final String date, @JsonProperty("measure") final String measure) {
        this(parseSingleDate(date), parseMeasure(measure));
    }

    public LocalDate getDate() {
        return mDate;
    }


    @JsonIgnore
    public String getDateFormatted() {
        return mDate.format(DateTimeFormatter.ofPattern(PATTERN_FORMAT_DATE_YYYY_MM_DD));
    }

    public float getDisplacementMeasurement() {
        return mDisplacementMeasurement;
    }

    @Override
    public long getDateMillis() {
        ZonedDateTime zdt = mDate.atStartOfDay().atZone(ZoneId.of("UTC"));
        return zdt.toInstant().toEpochMilli();
    }

    @Override
    public float getValue() {
        return mDisplacementMeasurement;
    }

    public boolean isAcquiredInDate(@NonNull final String date) {
        return this.mDate.equals(parseSingleDate(date));
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MeasureVO measureVO = (MeasureVO) o;
        return Objects.equals(mDate, measureVO.mDate);
    }

    @Override
    public int hashCode() {

        return Objects.hash(mDate);
    }

    @Override
    public String toString() {
        final ToStringBuilder toString = new ToStringBuilder(this, ToStringStyle.NO_CLASS_NAME_STYLE)
                .append("Date", getDateFormatted())
                .append("Displacement Measure", getDisplacementMeasurement())
                .append("Amplitude Measure", getAmplitudeMeasurement());
        return toString.toString();
    }

    public static LocalDate parseSingleDate(@NonNull final String toParse) throws IllegalArgumentException {
        return LocalDate.parse(toParse, mDateTimeFormatter);
    }

    private static float parseMeasure(final String toParse) throws IllegalArgumentException {
        float value;
        try {
            value = Float.valueOf(StringUtils.trimToEmpty(toParse));
        } catch (NumberFormatException e) {
            String message = String.format("The string '%s' cannot be parse into float. Error: %s", toParse, e.getMessage());
            log.error(message);
            throw new IllegalArgumentException(message);
        }
        return value;
    }

    public float getAmplitudeMeasurement() {
        return mAmplitudeMeasurement;
    }

    public void setAmplitudeMeasurement(float amplitudeMeasurement) {
        mAmplitudeMeasurement = amplitudeMeasurement;
    }

    public static class LocalDateAdapter implements JsonSerializer<LocalDate> {

        public JsonElement serialize(LocalDate date, Type typeOfSrc, JsonSerializationContext context) {
            return new JsonPrimitive(date.format(DateTimeFormatter.BASIC_ISO_DATE)); // "yyyymmdd"
        }
    }
}
