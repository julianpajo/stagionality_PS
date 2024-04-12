package it.planetek.rheticus.displacement.etl.util;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;

public class CropRowMapper implements RowMapper {

    public Object mapRow(ResultSet rs, int rowNum) throws SQLException {
        Crop org = new Crop();

        org.mId = rs.getInt("id");

        return org;
    }

    @Data
    @Accessors(prefix = "m")
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Crop {

        private Integer mId;
        
    }
}

