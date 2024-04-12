package it.planetek.rheticus.displacement.etl.util;

import org.springframework.batch.item.database.ItemSqlParameterSourceProvider;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;

import java.util.HashMap;

public class SimpleSqlParameterSourceProvider implements ItemSqlParameterSourceProvider<String> {

    @Override
    public SqlParameterSource createSqlParameterSource(final String item) {
        return new MapSqlParameterSource(new HashMap<String, Object>() {
            {
                put("id", item);
            }
        });
    }
}