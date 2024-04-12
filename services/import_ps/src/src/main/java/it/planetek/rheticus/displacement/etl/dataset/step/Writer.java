package it.planetek.rheticus.displacement.etl.dataset.step;

import it.planetek.rheticus.displacement.etl.common.Application;
import it.planetek.rheticus.displacement.etl.dataset.entity.Dataset;
import it.planetek.rheticus.displacement.etl.metadata.entity.Metadata;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.AfterStep;

import java.util.List;


@Slf4j
public class Writer extends org.springframework.batch.item.database.JdbcBatchItemWriter<Dataset> {

    @AfterStep
    public void afterStep(StepExecution stepExecution) {
        log.info(String.format("%s completed in: %d ms",
                               stepExecution.getStepName(),
                               System.currentTimeMillis() - stepExecution.getStartTime().getTime()));
    }

    @Override
    public void write(List<? extends Dataset> items) throws Exception {
        super.write(items);
    }

}
