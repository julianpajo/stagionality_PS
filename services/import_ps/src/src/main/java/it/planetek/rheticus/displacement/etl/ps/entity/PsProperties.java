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
public class PsProperties implements Serializable {

    private static final int PRECISION = 4;

    @SerializedName("a")
    private Float mAcceleration;

    @SerializedName("an")
    private Float mAccelerationNorm;

    @SerializedName("v")
    private Float mVelocity;

    @Builder
    public PsProperties(Float acceleration,
                        Float velocity) {

        mAcceleration = acceleration != null ? Precision.round(acceleration, PRECISION) : null;
        mVelocity = velocity != null ? Precision.round(velocity, PRECISION) : null;
    }
}
