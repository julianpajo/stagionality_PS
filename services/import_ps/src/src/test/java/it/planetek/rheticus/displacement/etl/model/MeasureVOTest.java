package it.planetek.rheticus.displacement.etl.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;

import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.runners.MockitoJUnitRunner;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import it.planetek.rheticus.displacement.etl.LoggingRule;
import it.planetek.rheticus.displacement.etl.ps.entity.MeasureVO;


@RunWith(MockitoJUnitRunner.class)
public class MeasureVOTest {
    private static final Logger log         = LoggerFactory.getLogger(MeasureVOTest.class);

    @Rule
    public LoggingRule          loggingRule = new LoggingRule(log);

    @Test
    public void create_new_with_valid_input() {
        // ginven
        LocalDate date = LocalDate.of(2018, 01, 01);
        Float meas = 15.5F;

        // when
        MeasureVO vo = new MeasureVO(date, meas);

        // then
        assertThat(date).isEqualTo(vo.getDate());
        assertThat(meas).isEqualTo(vo.getMeasure());
    }

    @Test
    public void create_new_with_valid_input_string() {
        // ginven
        String dateS = "2018-01-01";
        LocalDate date = LocalDate.of(2018, 01, 01);
        Float meas = 15.5F;

        // when
        MeasureVO vo = new MeasureVO(dateS, meas);

        // then
        assertThat(date).isEqualTo(vo.getDate());
        assertThat(meas).isEqualTo(vo.getMeasure());
        assertThat(dateS).isEqualTo(vo.getDateFormatted());
    }

    @Test(expected = IllegalArgumentException.class)
    public void create_new_with_invalid_input() {
        // ginven
        String dateS = "2018-00-01";
        Float meas = 15.5F;

        // when
        MeasureVO vo = new MeasureVO(dateS, meas);
    }

    @Test
    public void test_is_acquired_with_valid_date() {
        // ginven
        String dateS = "2018-01-01";
        Float meas = 15.5F;

        // when
        MeasureVO vo = new MeasureVO(dateS, meas);

        // then
        assertThat(vo.isAcquiredInDate(dateS)).isTrue();
        assertThat(vo.isAcquiredInDate("2018-01-02")).isFalse();
    }

    @Test(expected = IllegalArgumentException.class)
    public void test_is_acquired_with_invalid_date() {
        // ginven
        String dateS = "2018-01-01";
        Float meas = 15.5F;

        // when
        MeasureVO vo = new MeasureVO(dateS, meas);

        // then
        vo.isAcquiredInDate("2018-13-50");
    }
}
