document.getElementById("chart").style.display = "none";
document.getElementById("nodata").style.display = "none";

// Initialize the map with specified coordinates and zoom level
var map = L.map('map').setView([41.117143, 16.871871], 13);

mapLink =
    '<a href="http://www.esri.com/">Esri</a>';
wholink =
    'i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
L.tileLayer(
    'http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
    attribution: '&copy; '+mapLink+', '+wholink,
    maxZoom: 18,
    }).addTo(map);


var wmsLayer = L.tileLayer.wms('https://geoserver.euler.local/geoserver/euler/wms', {
    layers: 'euler:ps_measurements',
    format: 'image/png',
    transparent: true
}).addTo(map);

map.on('click', function(event) {

    var lat = event.latlng.lat;
    var lon = event.latlng.lng;
    var url = `/getFeatures?lat=${lat}&lon=${lon}`;

    fetch(url, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
    }).then(response => response.json())
    .then(data => {
        processData(data);
    })
    .catch(error => {
        console.error('Error retrieving data', error);
    });



});