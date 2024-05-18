import requests
import json
import datetime

api_key = None # Call api key locally


def main():
    try:
        # Get data from apod-api
        today = datetime.date.today()
        url = f'https://api.nasa.gov/planetary/apod?api_key={api_key}'
        result = requests.get(url).json()
        image = requests.get(result['hdurl'])
        # Download image
        with open(f"/home/yuri/Pictures/Wallpapers/APOD/apod_{today}.jpg", "wb") as f:
            f.write(image.content)
        return "Success"

    except:
        return "URL Error"  # Return reload icon


if __name__ == "__main__":
    main()
