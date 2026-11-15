import requests
import json

BASE_URL = "https://rata.digitraffic.fi/api/v1"
HEADERS = {
    "Digitraffic-User": "student/finland-elt-pipeline",
    "Accept-Encoding": "gzip",
}


def extract(date):
    response = requests.get(f"{BASE_URL}/trains/{date}", headers=HEADERS, timeout=30)
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    trains = extract("2026-11-11")
    print(json.dumps(trains[0], indent=2, ensure_ascii=False))
