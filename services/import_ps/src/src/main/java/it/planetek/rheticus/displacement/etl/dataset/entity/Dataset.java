package it.planetek.rheticus.displacement.etl.dataset.entity;

import lombok.*;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;

import javax.validation.constraints.NotNull;

@Data
@Accessors(prefix = "m")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class Dataset {

    @EqualsAndHashCode.Include
    private String mSensorCode;

    @EqualsAndHashCode.Include
    private String mSupermasterUid;

    @EqualsAndHashCode.Include
    private String mBeam;

    private String mDatasetName;
}
