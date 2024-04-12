package it.planetek.rheticus.displacement.etl.ps.step;

import it.planetek.rheticus.displacement.etl.ps.entity.Scatterer;
import it.planetek.rheticus.displacement.etl.ps.entity.ShapefileEntry;
import lombok.extern.slf4j.Slf4j;
import org.opengis.feature.simple.SimpleFeature;
import org.springframework.batch.item.ItemProcessor;


@Slf4j
public class ScattererProcessor implements ItemProcessor<ShapefileEntry, Scatterer> {

    @Override
    public Scatterer process(ShapefileEntry shapefileEntry) {
        if (shapefileEntry == null) return null;

        SimpleFeature feature = shapefileEntry.getDisplacementSimpleFeature();

        Scatterer.ScattererBuilder psBuilder = Scatterer.builder();

        Scatterer scatterer = psBuilder
                .cropIdentifier(shapefileEntry.getCropIdentifier())
                .code((String) feature.getAttribute("CODE"))
                .build();

        return scatterer;
    }
}
