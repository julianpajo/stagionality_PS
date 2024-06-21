import pytest
from src.app import app, calculate_bbox
from werkzeug.test import EnvironBuilder
from werkzeug.datastructures import Headers


class TestModule:
    """Test the module functions."""

    # Pytest fixture for the Flask application
    @pytest.fixture
    def client(self):
        app.config['TESTING'] = True
        with app.test_client() as client:
            yield client

    def test_getFeatures(self, client, requests_mock):
        """Test the getFeatures endpoint."""
        mock_response = '[{"id": 1, "name": "Feature"}]'
        requests_mock.get("http://restapi:8081/getFeatures", text=mock_response)

        response = client.get('/getFeatures', query_string={'lat': 45.0, 'lon': 9.0})

        assert response.status_code == 200
        assert response.data.decode('utf-8') == mock_response

    def test_getFeatures_with_cookie(self, client, requests_mock):
        """Test the getFeatures endpoint with a cookie."""
        mock_response = '[{"id": 1, "name": "Feature"}]'
        requests_mock.get("http://restapi:8081/getFeatures", text=mock_response)

        headers = Headers()
        headers.add('Cookie', '_oauth2_proxy=test_cookie')

        # Build the environment with the necessary cookie
        builder = EnvironBuilder(
            path='/getFeatures',
            method='GET',
            query_string={'lat': '45.0', 'lon': '9.0'},
            headers=headers.to_wsgi_list()
        )
        env = builder.get_environ()

        # Send the request using the client and the environment
        response = client.open(env)

        assert response.status_code == 200
        assert response.data.decode('utf-8') == mock_response

    def test_remove_stagionality_and_noise(self, client, monkeypatch):
        """Test the remove_stagionality_and_noise endpoint."""

        def mock_remove_stagionality_and_noise(measurements):
            return [0.1, 0.2, 0.3, 0.4, 0.5]

        # Use the correct path to the function
        monkeypatch.setattr('stagionality_analysis.remove_stagionality_and_noise',
                            mock_remove_stagionality_and_noise)

        data = {
            'measurements': [1.0, 2.0, 3.0, 4.0, 5.0]
        }
        response = client.post('/rm_stagionality_and_noise', json=data)

        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['trend'] == [0.1, 0.2, 0.3, 0.4, 0.5]

    def test_calculate_bbox(self):
        """Test the calculate_bbox function."""
        lon_min, lat_min, lon_max, lat_max = calculate_bbox(45.0, 9.0, 50)

        assert lon_min < 9.0
        assert lon_max > 9.0
        assert lat_min < 45.0
        assert lat_max > 45.0
