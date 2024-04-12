package it.planetek.rheticus.displacement.etl.util;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;

public class OrganizationRowMapper implements RowMapper {

    private static final String ALIAS_COLUMN = "alias";

    public Object mapRow(ResultSet rs, int rowNum) throws SQLException {
        Organization org = new Organization();

        org.mAlias = rs.getString(ALIAS_COLUMN);

        return org;
    }

    @Data
    @Accessors(prefix = "m")
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Organization {

        private String mAlias;

    }
}

