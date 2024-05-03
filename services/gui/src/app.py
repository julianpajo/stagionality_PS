from flask import Flask, render_template, request
import requests
from geopy.distance import distance

app = Flask(__name__)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/getFeatures', methods=['GET'])
def getFeatures():

    url = "http://restapi:8081/getFeatures"

    lat = float(request.args.get('lat'))
    lon = float(request.args.get('lon'))

    lon_min, lat_min, lon_max, lat_max = calculate_bbox(lat, lon, 50)

    params = {
        "lon_min": float(lon_min),
        "lat_min": float(lat_min),
        "lon_max": float(lon_max),
        "lat_max": float(lat_max),
    }

    response = requests.get(url, params=params)
    featureInfo = response.text

    return featureInfo


def calculate_bbox(lat, lon, gap_in_meters):

    lat_gap, lon_gap = distance(meters=gap_in_meters).destination((lat, lon), 0).latitude - lat, distance(meters=gap_in_meters).destination((lat, lon), 90).longitude - lon

    lat_min = lat - lat_gap
    lat_max = lat + lat_gap
    lon_min = lon - lon_gap
    lon_max = lon + lon_gap

    return lon_min, lat_min, lon_max, lat_max


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
