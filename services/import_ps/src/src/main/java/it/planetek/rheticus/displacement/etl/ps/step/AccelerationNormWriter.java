package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.util.CropRowMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.database.JdbcBatchItemWriter;

import java.util.List;

@Slf4j
public class AccelerationNormWriter extends JdbcBatchItemWriter<CropRowMapper.Crop> {

    @Override
    public void write(List<? extends CropRowMapper.Crop> items) throws Exception {
        long startTime = System.currentTimeMillis();

        for (CropRowMapper.Crop item : items) {
            log.info(String.format("Update acceleration_norm %s start", item.toString()));
        }

        super.write(items);

        for (CropRowMapper.Crop item : items) {
            log.info(String.format("Update acceleration_norm %s completed in: %d ms", item.getId(),
                                   System.currentTimeMillis() - startTime));
        }
    }
}
