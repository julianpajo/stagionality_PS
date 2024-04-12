package it.planetek.rheticus.displacement.etl.metadata.step;

import it.planetek.rheticus.displacement.etl.metadata.entity.Metadata;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.AfterStep;

import java.util.List;


@Slf4j
public class CropParameterWriter extends org.springframework.batch.item.database.JdbcBatchItemWriter<Metadata> {

    @AfterStep
    public void afterStep(StepExecution stepExecution) {
        log.info(String.format("%s completed in: %d ms",
                               stepExecution.getStepName(),
                               System.currentTimeMillis() - stepExecution.getStartTime().getTime()));
    }

    @Override
    public void write(List<? extends Metadata> items) throws Exception {
        super.write(items);
    }

}
