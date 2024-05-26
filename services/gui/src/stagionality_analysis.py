import numpy as np


def remove_stagionality_and_noise(measurements):

    time = np.arange(0, len(measurements))  # Assumiamo un periodo di campionamento unitario
    TimeSeries = np.array(measurements)

    # Costruzione della matrice modello (G)
    G = np.column_stack(
        (time ** 3, time ** 2, time, np.ones(len(time)), np.cos(2 * np.pi * time), np.sin(2 * np.pi * time)))

    # Inversione della matrice modello
    invG = np.linalg.pinv(G)
    COEFF = invG.dot(TimeSeries)

    # Calcolo del modello
    Model = G.dot(COEFF)

    # Calcolo della RMSE
    RMSE = np.sqrt(np.mean((TimeSeries - Model) ** 2))

    # Calcolo dell'ampiezza della componente stagionale e la sua deviazione standard
    EstimatedSeasonAMP = np.sqrt(COEFF[4] ** 2 + COEFF[5] ** 2)
    EstimatedSTD_SeasonAMP = np.sqrt((4 - np.pi) / 2 * (invG[4, 4] + invG[5, 5]) / 2) * RMSE

    # Calcolo della componente stagionale
    SeasonalComponent = G[:, 4:].dot(COEFF[4:])  # Componenti cosinusoidali e sinusoidali

    # Calcolo del residuo
    Residue = TimeSeries - Model

    # Sottrazione della componente stagionale e del residuo dal dato osservato
    Trend = TimeSeries - SeasonalComponent - Residue

    return Trend.tolist()
