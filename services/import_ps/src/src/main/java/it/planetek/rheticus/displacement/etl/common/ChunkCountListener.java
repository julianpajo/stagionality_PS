package it.planetek.rheticus.displacement.etl.common;

import lombok.Setter;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.batch.core.ChunkListener;
import org.springframework.batch.core.scope.context.ChunkContext;

import java.text.MessageFormat;
import java.util.Map;


@Slf4j
@Setter
@Accessors(prefix = "m")
public class ChunkCountListener implements ChunkListener {
    private MessageFormat mMessageFormat = new MessageFormat("#items: {2} - {0} - {1}");
    private int mLoggingInterval = 1000;
    private String mCropId;
    private String mShapefileName;
    private int mCommitInterval;
    private String mMaxKey;

    @Override
    public void beforeChunk(ChunkContext context) {
        //NOP
    }

    @Override
    public void afterChunk(ChunkContext context) {
        int count = context.getStepContext().getStepExecution().getReadCount();
        int commitCount = context.getStepContext().getStepExecution().getCommitCount();
        int maxCount = (int) context.getStepContext().getStepExecution().getExecutionContext().get(mMaxKey);

        if(count > maxCount ) {
            throw new RuntimeException("Unexpected count value: count > maxCount");
        }

        if (commitCount <= 0 || (count == maxCount && (count - ((commitCount - 1) * mCommitInterval)) <= 0)) {
            return;
        }

        log.info(mMessageFormat.format(new Object[]{mShapefileName, mCropId, new Integer(count)}));
    }

    @Override
    public void afterChunkError(ChunkContext context) {
        // NOP
    }

    public void setItemName(final String itemName) {
        if (StringUtils.isNotBlank(itemName)) {
            mMessageFormat = new MessageFormat("#" + itemName + ": {2} - {0} - {1}");
        }
    }


    public void setLoggingInterval(final int loggingInterval) {
        if (loggingInterval > 0 && loggingInterval < 500.0000) {
            mLoggingInterval = loggingInterval;
        }
    }

    public void setCommitInterval(int commitInterval) {
        mCommitInterval = commitInterval;
    }

    public void setMaxKey(String maxKey) {
        mMaxKey = maxKey;
    }
}
