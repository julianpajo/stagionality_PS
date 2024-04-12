package it.planetek.rheticus.displacement.etl.ps.entity;

import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;


@Data
@Accessors(prefix = "m")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Scatterer {

    private CropIdentifier mCropIdentifier;

    private String mCode;

}
