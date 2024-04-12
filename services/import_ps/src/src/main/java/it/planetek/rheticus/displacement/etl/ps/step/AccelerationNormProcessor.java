package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.util.CropRowMapper;
import org.springframework.batch.item.ItemProcessor;

public class AccelerationNormProcessor implements ItemProcessor<CropRowMapper.Crop, CropRowMapper.Crop> {

    @Override
    public CropRowMapper.Crop process(CropRowMapper.Crop item) throws Exception {
        return item;
    }
}