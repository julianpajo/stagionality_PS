package it.planetek.rheticus.displacement.etl.ps.step;

import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.AfterStep;

import java.util.List;


@Slf4j
public class ScattererWriter extends org.springframework.batch.item.database.JdbcBatchItemWriter {

    @AfterStep
    public void afterStep(StepExecution stepExecution) {
        log.info(String.format("%s completed in: %d ms",
                               stepExecution.getStepName(),
                               System.currentTimeMillis() - stepExecution.getStartTime().getTime()));
    }

    @Override
    public void write(List items) throws Exception {
        super.write(items);
    }
}
