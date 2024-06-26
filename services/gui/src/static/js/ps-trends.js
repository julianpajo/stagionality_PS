window.timeseries = null;
window.myChart = null;

document.getElementById('close-button').addEventListener('click', function() {
    document.getElementById('chart').style.display = 'none';
    destroyChart();
});

document.getElementById('close-button-nodata').addEventListener('click', function() {
    document.getElementById('nodata').style.display = 'none';
});

document.getElementById('close-button-permission-denied').addEventListener('click', function() {
    document.getElementById('permission-denied').style.display = 'none';
});

document.addEventListener('DOMContentLoaded', (event) => {
    const checkbox = document.getElementById('rm_stagionality_noise');

    checkbox.addEventListener('change', function() {
        if (this.checked) {
            remove_stagionality_and_noise(window.timeseries)
                .then(trend => {
                    updateChart(trend);
                })
                .catch(error => {
                    console.error(error);
            });
        } else {
            updateChart(window.timeseries);
        }
    });
});


function processData(data) {
    if (data.numberReturned === -1){
        var nodata = document.getElementById("permission-denied");
        document.getElementById('rm_stagionality_noise').checked = false;
        nodata.style.display = "block";
        nodata.classList.add('slide-in');
        setTimeout(function() {
            nodata.classList.remove('slide-in');
        }, 500);
    } else if (data.numberReturned === 1){
        destroyChart();
        document.getElementById('chart').style.display = 'block';
        document.getElementById('nodata').style.display = 'none';
        document.getElementById('rm_stagionality_noise').checked = false;
        var coordinates = data.features[0].geometry.coordinates;
        var latitude = coordinates[1];
        var longitude = coordinates[0];

        getCity(latitude, longitude);

        drawChart(data);
    } else {
        document.getElementById('chart').style.display = 'none';
        var nodata = document.getElementById("nodata");
        nodata.style.display = "block";
        nodata.classList.add('slide-in');
        setTimeout(function() {
            nodata.classList.remove('slide-in');
        }, 500);
    }
}

function getCity(lat, lon) {
    var url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`;
    fetch(url, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
    }).then(response => response.json())
    .then(data => {
        var city = data.address.city || data.address.town || data.address.village || data.address.hamlet || "Bari";
        var state = data.address.state || "Apulia";
        var country = data.address.country || "Paese non trovato";
        var latitude = data.lat || "Latitudine non disponibile";
        var longitude = data.lon || "Longitudine non disponibile";

        var locationElement = document.getElementById('ps-location');
        locationElement.textContent = city + ", " + state + ", " + country + ", [LAT: " + lat + "; LON: " + lon + "]";
    })
    .catch(error => {
        console.error('Error retrieving data', error);
    });
}

function drawChart(featureInfo) {

    var measurements = featureInfo.features[0].properties.measurement;
    var measurementsData = JSON.parse(measurements);

    var labels = measurementsData.d.map(function(dateString) {
        var year = dateString.substring(0, 4);
        var month = dateString.substring(4, 6);
        var day = dateString.substring(6, 8);
        return day + "/" + month + "/" + year;
    });



    var measurementsValues = measurementsData.m;
    window.timeseries = measurementsValues;

    var data = {
        labels: labels,
        datasets: [
            {
                label: 'Displacement',
                data: measurementsValues,
                borderColor: 'rgba(75, 192, 192, 1)',
                backgroundColor: 'rgba(75, 192, 192, 0.2)',
                tension: 0,
            },
        ],
    };

    var options = {
        responsive: true,
        plugins: {
            title: {
                display: true,
                text: 'Misurazioni senza Interpolazione',
            },
        },
        scales: {
            yAxes: [{
                scaleLabel: {
                    display: true,
                    labelString: 'Mappe di spostamento (mm)',
                }
            }],
            xAxes: [{
                ticks: {
                    display: false
                },
                scaleLabel: {
                    display: false
                }
            }]
    }
    };

    var ctx = document.getElementById('myChart').getContext('2d');
    window.myChart = new Chart(ctx, {
        type: 'line',
        data: data,
        options: options,
    });

    var ps_date_start = document.getElementById('ps-date-start');
    var ps_date_end = document.getElementById('ps-date-end');
    ps_date_start.textContent = labels[0];
    ps_date_end.textContent = labels[labels.length - 1];

    var ps_id = document.getElementById('ps-id');
    var ps_product = document.getElementById('ps-product');
    var ps_coherence = document.getElementById('ps-coherence');
    var ps_height = document.getElementById('ps-height');
    var ps_velocity = document.getElementById('ps-velocity');
    var ps_acceleration = document.getElementById('ps-acceleration');

    ps_id.textContent = featureInfo.features[0].properties.scatterer_id;
    ps_product.textContent = 'PS';
    ps_coherence.textContent = Math.round(featureInfo.features[0].properties.coherence * 100);
    ps_height.textContent = featureInfo.features[0].properties.height;

    periodic_properties = JSON.parse(featureInfo.features[0].properties.periodic_properties)

    ps_velocity.textContent = Math.round(periodic_properties.g.v * 10) / 10;
    ps_acceleration.textContent = Math.round(periodic_properties.g.a * 10) / 10;

}

function remove_stagionality_and_noise(timeseries) {
    return new Promise((resolve, reject) => {
        const url = '/rm_stagionality_and_noise';
        fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ measurements: timeseries })
        })
        .then(response => response.json())
        .then(data => {
            resolve(data.trend);
        })
        .catch(error => {
            console.error('Errore nella richiesta fetch:', error);
            reject(error);
        });
    });
}

function updateChart(newMeasurementsValues) {

    window.myChart.data.datasets[0].data = newMeasurementsValues;
    window.myChart.update();

}


function destroyChart() {
    // Find the <td> element containing the canvas
    var tdCanvasContainer = document.getElementById("canvasContainer");

    // Check if the element exists before attempting to remove and replace the canvas
    if (tdCanvasContainer) {
        // Find the canvas to be removed
        var canvasToRemove = tdCanvasContainer.querySelector("canvas");

        // Check if the canvas exists before attempting to remove it
        if (canvasToRemove) {
            // Remove the canvas
            canvasToRemove.remove();

            // Create a new canvas
            var newCanvas = document.createElement("canvas");
            newCanvas.id = "myChart";
            newCanvas.width = 700;
            newCanvas.height = 250;

            tdCanvasContainer.appendChild(newCanvas);
        }
    }
}


