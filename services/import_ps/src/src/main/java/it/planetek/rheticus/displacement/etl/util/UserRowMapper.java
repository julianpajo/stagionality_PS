package it.planetek.rheticus.displacement.etl.util;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;

public class UserRowMapper implements RowMapper {

    private static final String USERNAME_COLUMN = "username";

    public Object mapRow(ResultSet rs, int rowNum) throws SQLException {
        User user = new User();

        user.mUsername = rs.getString(USERNAME_COLUMN);

        return user;
    }

    @Data
    @Accessors(prefix = "m")
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class User {

        private String mUsername;

    }
}

