package it.planetek.rheticus.displacement.etl.dataset.step;

import it.planetek.rheticus.displacement.etl.dataset.entity.Dataset;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.ItemProcessor;


@Slf4j
public class Processor implements ItemProcessor<Dataset, Dataset> {

    @Override
    public Dataset process(Dataset dataset) throws Exception {
        return dataset;
    }

}
