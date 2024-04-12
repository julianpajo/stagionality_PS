package it.planetek.rheticus.displacement.etl.ps.entity;

import com.google.gson.annotations.SerializedName;
import lombok.*;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.math3.util.Precision;

import java.io.Serializable;

@Getter
@EqualsAndHashCode
@ToString
@Slf4j
@NoArgsConstructor
@Accessors(prefix = "m")
public class PsPeriodicPropertiesGlobal implements Serializable {
    private static final int PRECISION = 4;

    @SerializedName("a")
    private Float mAcceleration;

    @SerializedName("an")
    private Float mAccelerationNorm;

    @SerializedName("v")
    private Float mVelocity;

    @SerializedName("b")
    private Float mVelocityStd;

    @SerializedName("c")
    private Float mIncidenceAngle;

    @SerializedName("d")
    private Float mDirectionAngle;

    @SerializedName("e")
    private Float mSeasonalityComponent;

    @SerializedName("f")
    private Float mDisplacementMeanStd;

    @SerializedName("g")
    private Float mUpdateFlag;


    @Builder
    public PsPeriodicPropertiesGlobal(Float acceleration,
                        Float velocity, Float velocityStd, Float incidenceAngle, Float directionAngle,
                        Float seasonalityComponent, Float displacementMeanStd, Float updateFlag) {

        mAcceleration = acceleration != null ? Precision.round(acceleration, PRECISION) : null;
        mVelocity = velocity != null ? Precision.round(velocity, PRECISION) : null;
        mVelocityStd = velocityStd != null ?
                Precision.round(velocityStd, PRECISION) : null;
        mIncidenceAngle = incidenceAngle != null ? Precision.round(incidenceAngle, PRECISION) : null;
        mDirectionAngle = directionAngle != null ? Precision.round(directionAngle, PRECISION) : null;
        mSeasonalityComponent = seasonalityComponent != null ? Precision.round(seasonalityComponent, PRECISION) : null;
        mDisplacementMeanStd = displacementMeanStd != null ? Precision.round(displacementMeanStd, PRECISION) : null;
        mUpdateFlag = updateFlag != null ? Precision.round(updateFlag, PRECISION) : null;
    }
}
