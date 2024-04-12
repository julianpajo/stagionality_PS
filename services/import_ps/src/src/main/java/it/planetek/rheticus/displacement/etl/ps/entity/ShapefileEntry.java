package it.planetek.rheticus.displacement.etl.ps.entity;

import it.planetek.rheticus.displacement.etl.common.CropIdentifier;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import org.opengis.feature.simple.SimpleFeature;

@Data
@Accessors(prefix = "m")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShapefileEntry {

    private CropIdentifier mCropIdentifier;
    private Target mTarget;
    private SimpleFeature mDisplacementSimpleFeature;
    private SimpleFeature mAmplitudeSimpleFeature;

    public enum Target {
        PS("PS"),
        DS("DS"),
        CR("CR");

        private String mId;

        Target(String id) {
            mId = id;
        }

        public String getId() {
            return mId;
        }

        public static Target getValue(String value) {
            if (PS.mId.equalsIgnoreCase(value)) {
                return PS;
            } else if (DS.mId.equalsIgnoreCase(value)) {
                return DS;
            } else if (CR.mId.equalsIgnoreCase(value)) {
                return CR;
            }
            return PS;
        }
    }
}
