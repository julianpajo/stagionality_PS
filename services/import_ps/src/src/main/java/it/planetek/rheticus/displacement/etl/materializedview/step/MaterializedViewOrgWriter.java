package it.planetek.rheticus.displacement.etl.materializedview.step;

import it.planetek.rheticus.displacement.etl.util.OrganizationRowMapper;
import lombok.Setter;
import lombok.experimental.Accessors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.database.JdbcBatchItemWriter;

import java.util.List;

@Setter
@Accessors(prefix = "m")
@Slf4j
public class MaterializedViewOrgWriter extends JdbcBatchItemWriter<OrganizationRowMapper.Organization> {

    @Override
    public void write(List<? extends OrganizationRowMapper.Organization> items) throws Exception {
        long startTime = System.currentTimeMillis();

        for (OrganizationRowMapper.Organization item : items) {
            log.info(String.format("Refresh vwm_ps_%s start", item.getAlias()));
        }
        super.write(items);

        for (OrganizationRowMapper.Organization item : items) {
            log.info(String.format("Refresh vwm_ps_%s completed in: %d ms", item.getAlias(),
                                   System.currentTimeMillis() - startTime));
        }
    }
}