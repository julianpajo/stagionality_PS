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
public class PsPeriodicPropertiesLastYear implements Serializable {
    private static final int PRECISION = 4;

    @SerializedName("a")
    private Float mAcceleration;

    @SerializedName("an")
    private Float mAccelerationNorm;

    @SerializedName("v")
    private Float mVelocity;

    @SerializedName("h")
    private Float mVelocityStandardDeviation;

    @SerializedName("i")
    private Float mVelocityLin;

    @SerializedName("l")
    private Float mVelocityLinStandardDeviation;

    @SerializedName("m")
    private Float mVelocityCoherence;

    @Builder
    private PsPeriodicPropertiesLastYear(Float acceleration,
                                        Float velocity, Float velocityStandardDeviation, Float velocityLin,
                                        Float velocityLinStandardDeviation, Float velocityCoherence) {

        mAcceleration = acceleration != null ? Precision.round(acceleration, PRECISION) : null;
        mVelocity = velocity != null ? Precision.round(velocity, PRECISION) : null;
        mVelocityStandardDeviation = velocityStandardDeviation != null ?
                Precision.round(velocityStandardDeviation, PRECISION) : null;
        mVelocityLin = velocityLin != null ? Precision.round(velocityLin, PRECISION) : null;
        mVelocityLinStandardDeviation = velocityLinStandardDeviation != null ?
                Precision.round(velocityLinStandardDeviation, PRECISION) : null;
        mVelocityCoherence = velocityCoherence != null ? Precision.round(velocityCoherence, PRECISION) : null;
    }
}
