package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.common.Application;
import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import it.planetek.rheticus.displacement.etl.util.CropRowMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.BeforeStep;
import org.springframework.batch.item.database.JdbcCursorItemReader;
import org.springframework.jdbc.core.ArgumentPreparedStatementSetter;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
//TODO replace JdbcCursorItemReader with JdbcCursorItemReader to fix connection leak issue
public class AccelerationNormReader extends JdbcCursorItemReader<CropRowMapper.Crop> {

    public AccelerationNormReader() {
        setName("ACCELERATION_NORM");
    }

    @BeforeStep
    public void beforeStep(StepExecution stepExecution) {
        Set<CropIdentifier> cropIdentifiers = Application.getInstance().getCropIdentifiers();
        List<String> sensorCodes = cropIdentifiers.stream().map(CropIdentifier::getSensorCode)
                                                  .collect(Collectors.toList());
        List<String> supermasterUids = cropIdentifiers.stream().map(CropIdentifier::getSupermasterUid)
                                                      .collect(Collectors.toList());
        List<String> beams = cropIdentifiers.stream().map(CropIdentifier::getBeam)
                                            .collect(Collectors.toList());
        List<String> cropCodes = cropIdentifiers.stream().map(CropIdentifier::getCode)
                                                .collect(Collectors.toList());
        ArgumentPreparedStatementSetter argumentPreparedStatementSetter =
                new ArgumentPreparedStatementSetter(new Object[]{
                        String.join(",", cropCodes),
                        String.join(",", sensorCodes),
                        String.join(",", supermasterUids),
                        String.join(",", beams)
                });
        setPreparedStatementSetter(argumentPreparedStatementSetter);


        log.info(cropIdentifiers.toString());
    }

    @Override
    public synchronized CropRowMapper.Crop read() throws Exception {
        return super.read();
    }

    @Override
    protected CropRowMapper.Crop readCursor(ResultSet rs, int currentRow) throws SQLException {
        CropRowMapper.Crop crop = super.readCursor(rs, currentRow);
        return crop;
    }
}
