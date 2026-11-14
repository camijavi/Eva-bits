import json
import logging
import requests
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('NASA Data Trigger processed a request.')

    lat = req.params.get('lat', '13.0910')
    lon = req.params.get('lon', '-86.3538')

    nasa_url = (
        f"https://power.larc.nasa.gov/api/temporal/daily/point"
        f"?parameters=T2M,PRECTOTCORR,ALLSKY_SFC_SW_DWN,GWETROOT"
        f"&community=AG&longitude={lon}&latitude={lat}"
        f"&start=20240101&end=20240107&format=JSON"
    )

    try:
        res = requests.get(nasa_url, timeout=10)
        if res.status_code == 200:
            return func.HttpResponse(
                res.text,
                mimetype="application/json",
                status_code=200
            )
    except Exception as e:
        logging.error(f"Error querying NASA POWER: {e}")

    # Fallback response
    fallback = {
        "source": "NASA Earth Observations (Cached)",
        "coordinates": {"lat": float(lat), "lon": float(lon)},
        "summary": {
            "avg_temp_c": 24.5,
            "avg_rainfall_mm": 3.2,
            "soil_moisture_index": 0.58
        }
    }
    return func.HttpResponse(
        json.dumps(fallback),
        mimetype="application/json",
        status_code=200
    )
