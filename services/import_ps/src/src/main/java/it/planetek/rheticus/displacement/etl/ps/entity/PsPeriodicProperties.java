package it.planetek.rheticus.displacement.etl.ps.entity;

import com.google.gson.annotations.SerializedName;
import lombok.*;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;

import java.io.Serializable;

@Getter
@EqualsAndHashCode
@ToString
@NoArgsConstructor
@Slf4j
@Accessors(prefix = "m")
public class PsPeriodicProperties implements Serializable {

    @SerializedName("g")
    private PsPeriodicPropertiesGlobal mGlobal;

    @SerializedName("ly")
    private PsPeriodicPropertiesLastYear mLastYear;

    @Builder
    public PsPeriodicProperties(PsPeriodicPropertiesGlobal global,
                                PsPeriodicPropertiesLastYear lastYear) {
        mGlobal = global;
        mLastYear = lastYear;
    }
}
