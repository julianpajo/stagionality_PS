package it.planetek.rheticus.displacement.etl.common;

import java.util.HashSet;
import java.util.Set;

public class Application {
    private static Application ourInstance = new Application();
    private Set<CropIdentifier> mCropIdentifiers;

    public static Application getInstance() {
        return ourInstance;
    }

    private Application() {
        mCropIdentifiers = new HashSet<>();
    }

    public Set<CropIdentifier> getCropIdentifiers() {
        return mCropIdentifiers;
    }

    public synchronized void addCropIdentifier(CropIdentifier cropId) {
        mCropIdentifiers.add(cropId);
    }
}
