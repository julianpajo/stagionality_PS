package it.planetek.rheticus.displacement.etl.ps.entity;

import lombok.*;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDate;

@Getter
@EqualsAndHashCode
@ToString
@NoArgsConstructor
@AllArgsConstructor
@Slf4j
@Accessors(prefix = "m")
public class Period {
    LocalDate mStartDate;
    LocalDate mEndDate;
}
