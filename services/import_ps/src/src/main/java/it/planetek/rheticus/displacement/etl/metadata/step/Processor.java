package it.planetek.rheticus.displacement.etl.metadata.step;

import it.planetek.rheticus.displacement.etl.metadata.entity.Metadata;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.ItemProcessor;


@Slf4j
public class Processor implements ItemProcessor<Metadata, Metadata> {

    @Override
    public Metadata process(Metadata metadata) throws Exception {
        return metadata;
    }

}
