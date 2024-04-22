from flask import Flask, jsonify, render_template
from cachetools import cached, TTLCache
import requests

app = Flask(__name__)

cache = TTLCache(maxsize=100, ttl=300)


@cached(cache)
def get_ps_properties():
    # Definisci l'URL della richiesta POST
    url = "http://geoserver:8080/geoserver/euler/wms?service=WMS&version=1.1.0&request=GetMap&layers=test:test&bbox=16.801172256469727,41.06619644165039,1885212.875,5032619.5&width=330&height=768&srs=EPSG:3857&styles=&format=application/json;type=geojson"

    # Effettua la richiesta POST
    response = requests.post(url)

    # Verifica se la richiesta ha avuto successo
    if response.status_code == 200:
        # Ottieni il contenuto della risposta in formato JSON
        data = response.json()

        # Inizializza una lista vuota per le proprietà
        properties_list = []

        # Itera su tutte le features nel GeoJSON
        for feature in data.get('features', []):
            # Verifica se ci sono proprietà nell'oggetto
            if 'properties' in feature:
                # Aggiungi le proprietà dell'oggetto alla lista
                properties_list.append(feature['properties'])

        return properties_list
    else:
        return None


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/get_coordinates')
def get_ps_coordinates():
    ps_properties = get_ps_properties()
    if ps_properties:
        # Restituisci tutte le proprietà raccolte
        return jsonify(ps_properties)
    else:
        return jsonify({'error': 'No properties found'})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
