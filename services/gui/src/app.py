from flask import Flask, render_template, request, jsonify
import requests
from geopy.distance import distance
from flask_cors import CORS
import stagionality_analysis


app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/getFeatures', methods=['GET'])
def getFeatures():
    url = "http://restapi:8081/getFeatures"

    lat = float(request.args.get('lat'))
    lon = float(request.args.get('lon'))

    lon_min, lat_min, lon_max, lat_max = calculate_bbox(lat, lon, 50)

    cookie_value = request.cookies.get('_oauth2_proxy')

    if cookie_value:
        cookies = {'_oauth2_proxy': cookie_value}
    else:
        cookies = None

    params = {
        "lon_min": float(lon_min),
        "lat_min": float(lat_min),
        "lon_max": float(lon_max),
        "lat_max": float(lat_max),
    }

    response = requests.get(url, params=params, cookies=cookies)

    featureInfo = response.text

    return featureInfo


@app.route('/rm_stagionality_and_noise', methods=['POST'])
def remove_stagionality_and_noise():
    data = request.json
    measurements = data.get('measurements')
    trend = stagionality_analysis.remove_stagionality_and_noise(measurements)

    return jsonify({'trend': trend})


def calculate_bbox(lat, lon, gap_in_meters):
    lat_gap, lon_gap = distance(meters=gap_in_meters).destination((lat, lon), 0).latitude - lat, distance(
        meters=gap_in_meters).destination((lat, lon), 90).longitude - lon

    lat_min = lat - lat_gap
    lat_max = lat + lat_gap
    lon_min = lon - lon_gap
    lon_max = lon + lon_gap

    return lon_min, lat_min, lon_max, lat_max


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
