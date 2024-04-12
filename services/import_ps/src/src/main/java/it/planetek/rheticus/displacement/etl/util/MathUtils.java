package it.planetek.rheticus.displacement.etl.util;

import java.util.List;

public class MathUtils {

    public static double linearRegression(List<? extends SupportLinearRegression> values) {
        double slope;
        double intercept;
        double r2;

        int n = values.size();
        double sum_x = 0;
        double sum_y = 0;
        double sum_xy = 0;
        double sum_xx = 0;
        double sum_yy = 0;

        long milliToDay = 86400000;            // 1[day] = 24[h]*60[min]*60[sec]*1000[millisec] = 86400000[millisec]
        long milliToYear = 365 * milliToDay;    // 1[year] = 365*1[day] = 31536000000[millisec]

        for (int i = n - 1; i >= 0; i--) {
            //x = date expressed in years
            double xTime = (double) (values.get(i).getDateMillis() - values.get(n - 1).getDateMillis()) / milliToYear;
            //y = measures in mm
            float yMeasure = values.get(i).getValue();

            sum_x += xTime;
            sum_y += yMeasure;
            sum_xy += (xTime * yMeasure);
            sum_xx += (xTime * xTime);
            sum_yy += (yMeasure * yMeasure);
        }

        slope = ((n * sum_xy) - (sum_x * sum_y)) / ((n * sum_xx) - (sum_x * sum_x));
        intercept = (sum_y - (slope * sum_x)) / n;
        r2 = Math.pow(((n * sum_xy) - (sum_x * sum_y)) / Math.sqrt(((n * sum_xx) - (sum_x * sum_x)) * ((n * sum_yy) - (sum_y * sum_y))), 2);

        return slope;
    }

    public static float average(List<Float> elmt) {
        double sum = 0;
        for (Float anElmt : elmt) {
            sum += anElmt;
        }
        return (float) (sum / elmt.size());
    }


    public interface SupportLinearRegression {
        long getDateMillis();
        float getValue();
    }
}
