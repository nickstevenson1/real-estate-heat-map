import getpass
import pg8000
import json
import pandas as pd
import geopandas as gpd
import webbrowser
import folium
import csv

user = input("Username: ")
secret = getpass.getpass()
db = pg8000.connect(user=user, password=secret, host='codd.mines.edu', port=5433, database='csci403')
cursor = db.cursor()

geo_file = 'data/denver_map.geojson'
gdf = gpd.read_file(geo_file)
gdf['nbhd_name'] = gdf['nbhd_name'].str.upper()

m = folium.Map(
    location=[39.73715, -104.989174],
    tiles='"http://{s}.tiles.mapbox.com/v4/wtgeographer.2fb7fc73/{z}/{x}/{y}.png?access_token=pk.xxx',
    attr='XXX Mapbox Attribution',
    zoom_start = 11
)

with open("data/neighborhood_price_growth.csv", "w", newline="") as f:
    csv_writer = csv.writer(f)
    cursor.execute('''select c.name, avg(price_growth) as avg_price_growth from
    (select n.name as name, 
    (avg(sale_price) - lag(avg(sale_price)) over (order by n.name, extract(year from reception_date))) / (lag(avg(sale_price)) over (order by n.name, extract(year from reception_date)) + 1) as price_growth, 
    extract(year from reception_date) as year 
    from property
    join neighborhood n on n.number = nbhd_1
    join d_class d on d.id = d_class
    where d.name like 'RESIDENTIAL%' and extract(year from reception_date) > 2010
    group by n.name, extract(year from reception_date) 
    order by n.name, extract(year from reception_date)) as c
    where c.price_growth < 10
    group by c.name''')
    results = cursor.fetchall()
    csv_writer.writerow(["nbhd_name", "avg_price_growth"])
    csv_writer.writerows(results)

neighborhood_data = pd.read_csv('data/neighborhood_price_growth.csv')

folium.Choropleth(
    geo_data = gdf,
    data = neighborhood_data,
    columns = ["nbhd_name", "avg_price_growth"],
    threshold_scale = [-1.0, -0.8, -0.6, -0.4, -0.2, 0, 0.25, 0.5, 1.0, 1.7],
    key_on = 'feature.properties.nbhd_name',
    fill_color = 'YlGn',
    fill_opacity = 0.7,
    line_opacity = .1,
    legend_name = 'value'
).add_to(m)

folium.LayerControl().add_to(m)
gdf['long'] = gdf.centroid.x
gdf['lat'] = gdf.centroid.y

for i, row in gdf.iterrows():
    per = neighborhood_data.loc[neighborhood_data['nbhd_name'] == row['nbhd_name']][['avg_price_growth']].values
    if per:
        folium.Marker(
            location = [row['lat'], row['long']],
            popup = folium.Popup('<b>'+row['nbhd_name']+ '</b>\n<b>'+ str(round(per[0][0]*100, 2)) + '%</b>', show=False),
            icon = folium.Icon(color='red', icon='apartment')
        ).add_to(m)

m.save("neighborhood_map.html")
webbrowser.open("neighborhood_map.html")

airbnb_data = pd.read_csv('data/airbnb_data.csv')

for i, row in airbnb_data.iterrows():
    folium.Marker(
        location = [row['latitude'], row['longitude']],
        popup = folium.Popup('<b>'+str(row['price']) + '</b>', show=False),
        icon = folium.Icon(color='red', icon='info_sign')
    ).add_to(m)

m.save("airbnb_map.html")
webbrowser.open("airbnb_map.html")
