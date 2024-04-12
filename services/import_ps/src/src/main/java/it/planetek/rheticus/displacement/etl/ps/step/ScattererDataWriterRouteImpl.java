package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.ps.entity.Ps;
import org.springframework.classify.annotation.Classifier;

public class ScattererDataWriterRouteImpl {

    @Classifier
    public String classify(Ps ps) {
        switch (ps.getTarget()) {
            case PS:
                return "ps";
            case DS:
                return "ds";
            case CR:
                return "cr";
            default:
                return "ps";
        }
    }
}
