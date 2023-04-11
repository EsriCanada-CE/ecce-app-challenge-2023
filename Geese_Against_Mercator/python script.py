import requests
import datetime
import arcpy

#Provided the API key to make it possible to run this script if interested for the ECCE competition
#A different key will be used in the long run
temporary_api_key = '6bcd99cc280f628876520c5cef165e92'

def get_weather(lat, lon, time):
    url = f"https://api.openweathermap.org/data/3.0/onecall/timemachine?lat={lat}&lon={lon}&dt={time}&appid={temporary_api_key}&units=metric"
    response = requests.get(url)

    data = response.json()
    temp = data['data'][0]['temp']
    pressure = data['data'][0]['pressure']
    humidity = data['data'][0]['humidity']
    wind_speed = data['data'][0]['wind_speed']
    wind_deg = data['data'][0]['wind_deg']
    weather_description = data['data'][0]['weather'][0]['description']
    #Populate attribute table columns with these values
    print(f"Temperature: {temp}°C")
    print(f"Pressure: {pressure} hPa")
    print(f"Humidity: {humidity}%")
    print(f"Wind speed: {wind_speed} m/s")
    print(f"Wind degree: {wind_deg}°")
    print(f"Weather description: {weather_description}")
    print("")
    return 

aprx = arcpy.mp.ArcGISProject("CURRENT")

map = aprx.activeMap

# Get coordinates from existing survey points
layer = map.listLayers()[0]
    
with arcpy.da.SearchCursor(layer, ["SHAPE@XY", "CreationDate"]) as cursor:
    for xy, creation_date in cursor:
        lon, lat = xy
        print(f"Creation date: {creation_date}")
        time = int(creation_date.timestamp())
        print(f"time: {time}")
        get_weather(lat, lon, time)
