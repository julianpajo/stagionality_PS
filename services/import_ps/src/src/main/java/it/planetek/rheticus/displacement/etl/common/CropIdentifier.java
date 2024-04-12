package it.planetek.rheticus.displacement.etl.common;

import lombok.*;
import lombok.experimental.Accessors;

@Data
@Accessors(prefix = "m")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class CropIdentifier {

    @EqualsAndHashCode.Include
    private String mSensorCode;

    @EqualsAndHashCode.Include
    private String mSupermasterUid;

    @EqualsAndHashCode.Include
    private String mBeam;

    @EqualsAndHashCode.Include
    private String mCode;
}
