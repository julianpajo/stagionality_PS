package it.planetek.rheticus.displacement.etl.common;

import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import javax.annotation.Resource;

//TODO Improve this solution
public class UpdateTaskExecutorTasklet implements Tasklet {

    @Value("${maxConcurrencyLimit}")
    private int mMaxConcurrencyLimit;

    @Resource(name = "importTaskExecutor")
    ThreadPoolTaskExecutor mImportTaskExecutor;

    @Resource(name = "importMeasurementTaskExecutor")
    ThreadPoolTaskExecutor mImportMeasurementTaskExecutor;

    @Resource(name = "updateAccelerationNormTaskExecutor")
    ThreadPoolTaskExecutor mUpdateAccelerationNormTaskExecutor;

    @Resource(name = "refreshMvTaskExecutor")
    ThreadPoolTaskExecutor mRefreshMvTaskExecutor;

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        mImportTaskExecutor.setCorePoolSize(mMaxConcurrencyLimit);
        mImportMeasurementTaskExecutor.setCorePoolSize(mMaxConcurrencyLimit);
        mUpdateAccelerationNormTaskExecutor.setCorePoolSize(mMaxConcurrencyLimit);
        mRefreshMvTaskExecutor.setCorePoolSize(mMaxConcurrencyLimit);
        return null;
    }
}
