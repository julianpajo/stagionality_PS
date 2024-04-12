package it.planetek.rheticus.displacement.etl.metadata.entity;

import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import lombok.*;
import lombok.experimental.Accessors;

@Data
@Accessors(prefix = "m")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class Metadata {

    @EqualsAndHashCode.Include
    private String mSensorCode;

    @EqualsAndHashCode.Include
    private String mSupermasterUid;

    @EqualsAndHashCode.Include
    private String mBeam;

    @EqualsAndHashCode.Include
    private String mCode;

    private double mMinLat;

    private double mMaxLat;

    private double mMinLon;

    private double mMaxLon;

    //TODO remove after
    private String mName;

    private String mMetadata;

    private String mPass;

    private double mCohSuggested;

    private double mCohMin;

    private final int mStatus = 1;

    private ShapefileEntry.Target mTarget;
}
