**Final Project IA626 - Weather API**
##### Author: Rakesh Kantharaju

Project Description:

Build an API which gets you daily and hourly weather data for year 2022.

Overall process:

- We have weather data stored in csv files and each csv file contains either houlry or daily weather data for a given station.We also have csv files which contains all the zip codes info all over the world.
- For our API to query the data, we need to store this data in structered tables in a database, therefore I use docker to create a MySQL local instance, and create database and tables to load this data.
- Build a loader file in python which automatically reads the data, cleans it and do tranformations and finally load the data in respetive tables.
- Once the data is stored, build the api with the required endpoints and also the SQL queries to fetch data from tables. Build test cases for each endpoint to make sure it returns meaningfull results.

## Weather dataset

The dataset is provided by `National Centers for Environmental Information`. You can find the dataset here. 

Hourly weather data
https://www.ncei.noaa.gov/data/global-hourly/archive/csv/ 

Daily weather data
https://www.ncei.noaa.gov/data/global-summary-of-the-day/archive/

Lets understand the datasets here.

#### Hourly weather

You can look at the sample data for hourly weather in 'sample_files' folder.

##### Data Description
( Detailed data description is available in data_description folder)

STATION - Station identifier no 

DATE - Date the record is captured

SOURCE - The flag of a GEOPHYSICAL-POINT-OBSERVATION showing the source or combination of sources used in creating the
observation

LATITUDE & LONGITUDE - Geo point location of the station

ELEVATION - The elevation of a GEOPHYSICAL-POINT-OBSERVATION relative to Mean Sea Level (MSL).

NAME - Station name

REPORT_TYPE - The code that denotes the type of geophysical surface observation.

CALL_SIGN - The identifier that represents the call letters assigned to a FIXED-WEATHER-STATION.

QUALITY_CONTROL - The name of the quality control process applied to a weather observation.

WND - Wind Observation values 
    (a,b,c,d,e)

    a - direction angle
    b - direction quality code
    c - type code
    d - speed rate
    e - speed quality code

CIG - Sky condition Observation values
(a,b,c,d)

    a - ceiling height dimension
    b - ceiling quality code
    c - ceiling determination code
    d - cavok code

VIS - Visibility Observation values
(a,b,c,d)

    a - distance dimension
    b - distance quality code
    c - variability code
    d - quality variability code

TMP - Air Temperature Observation
(a,b)

    a - air temperature
    b - air temperature quality code

DEW - Air Dew point Observation
(a,b)

    a - air dew point temperature
    b - air dew point quality code

SLP - Sea level Observation 
(a,b)

    a - sea level pressure
    b - sea level pressure quality code

#### Daily weather

You can look at the sample data for hourly weather in 'sample_files' folder.

##### Data Description
( Detailed data description is available in data_description folder)

FIELD DESCRIPTION\
STATION - Station number (WMO/DATSAV3 possibly combined w/WBAN number)\
DATE - Given in mm/dd/yyyy format\
LATITUDE - Given in decimated degrees (Southern Hemisphere values are negative)\
LONGITUDE - Given in decimated degrees (Western Hemisphere values are negative)\
ELEVATION - Given in meters\
NAME - Name of station/airport/military base\
TEMP - Mean temperature for the day in degrees Fahrenheit to tenths. Missing = 9999.9\
TEMP_ATTRIBUTES - Number of observations used in calculating mean temperature.\
DEWP - Mean dew point for the day in degrees Fahrenheit to tenths. Missing = 9999.9\
DEWP_ATTRIBUTES - Number of observations used in calculating mean dew point.\
SLP - Mean sea level pressure for the day in millibars to tenths. Missing = 9999.9\
SLP_ATTRIBUTES - Number of observations used in calculating mean sea level pressure.\
STP - Mean station pressure for the day in millibars to tenths. Missing = 9999.9\
STP_ATTRIBUTES - Number of observations used in calculating mean station pressure.\
VISIB - Mean visibility for the day in miles to tenths. Missing = 999.9\
VISIB_ATTRIBUTES - Number of observations used in calculating mean visibility.\
WDSP - Mean wind speed for the day in knots to tenths. Missing = 999.9\
WDSP_ATTRIBUTES - Number of observations used in calculating mean wind speed.\
MXSPD - Maximum sustained wind speed reported for the day in knots to tenths. Missing =
999.\
GUST - Maximum wind gust reported for the day in knots to tenths. Missing = 999.9\
MAX - Maximum temperature reported during the day in Fahrenheit to tenths. Missing = 9999.9\
Note: Time of maximum temperature report varies by country and region, so this will sometimes
not be the maximum for the calendar day. 



## Create local MYSQL instance using docker
Docker is a platform for developing, shipping, and running applications in containers. Containers are lightweight, standalone, and executable packages that include everything needed to run a piece of software, including the code, runtime, libraries, and system tools. Docker provides a consistent and portable environment across different machines, making it easier to deploy and scale applications.

* Step 1 : Download and install docker from the given site.
https://www.docker.com/products/docker-desktop/
* Step 2 : Make sure your docker is up and running.
* Step 3 : Create a folder similar to 'docker_r' created in this project and create a Docker Compose configuration file, which is used to define and manage multi-container Docker applications. This specific configuration defines two services, mysql and myadmin, and sets up a MySQL database and a PHPMyAdmin interface.

```yaml
services:
  mysql:
    image: mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: "password"
    volumes:
      - ./mysql_data:/var/lib/mysql
  myadmin:
    image: phpmyadmin
    links:
      - mysql:db
    ports:
      - "8080:80"
```
* Step 4 : Open the terminal , go to the docker folder and run the command `docker compose up` which  starts the Docker containers defined in a Docker Compose configuration file.
* Step 5 : Go to `localhost:8080` which should open the login page of phpmyadmin, username=root and password is 'password' as given in config file(can be changed this if needed). Your MySQL server is ready and you can start using it.
* Step 6 : Create two databases `weather_houlry` and `weather` for our api project.

### Build python loader files

The loader files job is to read the required csv files from the folders and cleans the data, perform transformations and finally load the data in MySQL tables.

#### Load hourly weather data

Considering the data size of hourly weather data for all stations over the world for a given year, I am loading the weather data for stations whose location fall under this polygon.

<img src='Images/weather_data_polygon.png' width='380'>

The coordinates for this polygon is stored in 'polygon_geojson.txt' file.We will be using this file in our loader script.

Lets look at our loader script

*hourly_weather_loader.ipynb*

Import necessary packages

```python
import pandas as pd
import csv
import numpy as np
import glob
import os
from datetime import datetime
from sqlalchemy import create_engine
import pgeocode
from sqlalchemy import event
import swifter
import time
from pandarallel import pandarallel
import json
from shapely import Polygon
from shapely import Point, LineString
import warnings

# Ignore all warnings
warnings.filterwarnings("ignore")
pd.set_option('display.max_columns', None)
pd.set_option('display.expand_frame_repr', False)

```

Let's look at a sample weather houlry dataset

```python
sample=pd.read_csv('station_files_hourly/01001099999.csv')
sample.head(3)
```

<img src='Images/weather_hourly_sample_dataset.png' width='580'>

Read the polygon file and extract latitude and longitude values.
Create a polygon using these coordinates and test if potsdam coordinates fall under this polygon.

```python
f=open('polygon.txt','r') # open file 
p=json.load(f) # load json
print(p)

```
<img src='Images/polygon_json.png' width='580'>

```python
coordinates = p['geometry']['coordinates'][0] # get coordinates

for i in range(len(coordinates)): # rearrange lon,lat to lat,lon
    coordinates[i]=coordinates[i][::-1]

print(coordinates)
```
<img src='Images/coordinates.png' width='380' height='100'>

```python
# create a polygon and test is potsdam cooridnates fall under this polygon

polygon = Polygon(coordinates)
point = Point(44.5588, -72.5778)
print(polygon.contains(point))

```
<img src='Images/true.png' width='780' height='20'>

Iterate through all the files in the 'station_files_hourly' folder and create a list of paths for each file.Once the list is created ,
iterate through all files using the paths list and read first lines of each file to extract the lat and lon values.We dont need to read the whole file to get the coordinates because lat and lon values for a station will be the same for all the rows.\

While you iterate through and extract the lat and lon value, check convert these values to a point and check if this point falls under the polygon that we created.If yes, append that file path, lat and lon values to a dictionary.\

Once you have a dictionary of all the station file paths which fall under the polygon, iterate through the dict and read all the files and concat to a dataframe for our further analysis.\

This way we will have all stations which fall under that polygon and their data concated to a dataframe.

```python
# create a list of station file paths
files = glob.glob("station_files_hourly/*.csv")

# iterate through the above list and create the dictionary as discussed above

d={}
n=0
for file in files:
    f=csv.reader(open(file,'r'))
    next(f)
    for line in f:
        point = Point(line[3],line[4])
        if polygon.contains(point):
            d[line[0]]={}
            d[line[0]]['latitude']=line[3]
            d[line[0]]['longitude']=line[4]
            d[line[0]]['path']=file
        break
    n+=1
    if n%1000==0:
        print(n)

print(d)
```

<img src='Images/path_dict.png' width='500' height='400'>

Read only required columns and handle files which has missing columns by filling 999999 as missing values.

```python
required_cols=['STATION','DATE','LATITUDE','LONGITUDE','NAME','WND','CIG','VIS','TMP','DEW','SLP','KA1','KA2','MA1','MD1','OC1','OD1']
fdf=[]
for station,v in d.items():
    file=v['path']
    df=pd.read_csv(file)
    for col in required_cols:
        if col not in df.columns:
            df[col]=999999
    fdf.append(df[required_cols])  
    
frame = pd.concat(fdf, axis=0, ignore_index=True)
frame.head()
```

<img src='Images/frame_hourly.png' width='580' >

Handle datatypes and Tranformations

```python
# check if station numbers are unique in each file
print("Unique station count:",frame.STATION.nunique())
print("no of files:",len(d))

```
<img src='Images/check_unique_stations_hourly.png' width='580' >


```python
# expand weather metrics as per data description
frame[['WIND_DIRECTION_ANGLE','WIND_DIRECTION_QUALITY_CODE','WIND_TYPE_CODE','WIND_SPEED_RATE','WIND_SPEED_QUALITY_CODE']]=frame['WND'].str.split(',',expand=True)
frame[['SKY_CEILING_HEIGHT','SKY_CEILING_QUALITY','SKY_CEILING_DETERMINATION','SKY_CEILING_CAVOK_CODE']]=frame['CIG'].str.split(',',expand=True)
frame[['VIS_DISTANCE_DIM','VIS_DISTANCE_QUALITY','VIZ_VARIABILITY','VIZ_QUALITY_VARIABILITY']]=frame['VIS'].str.split(',',expand=True)
frame[['AIR_TEMP','AIR_TEMP_QUALITY']]=frame['TMP'].str.split(',',expand=True)
frame[['AIR_DEW','AIR_DEW_QUALITY']]=frame['DEW'].str.split(',',expand=True)
frame[['ATM_PRESSURE','ATM_PRESSURE_QUALITY']]=frame['SLP'].str.split(',',expand=True)
frame=frame.drop(['WND','CIG','VIS','TMP','DEW','SLP'],axis=1)

# create station name and country columns seperately from name column
frame[['NAME','COUNTRY_CODE']]=frame['NAME'].str.split(', ',expand=True)
frame['COUNTRY_CODE']=frame['COUNTRY_CODE'].apply(lambda x: str(x)[-2:])

# change the column order
cols_order=['STATION', 'DATE', 'LATITUDE', 'LONGITUDE', 'NAME','COUNTRY_CODE',  'WIND_DIRECTION_ANGLE',
       'WIND_DIRECTION_QUALITY_CODE', 'WIND_TYPE_CODE', 'WIND_SPEED_RATE',
       'WIND_SPEED_QUALITY_CODE', 'SKY_CEILING_HEIGHT', 'SKY_CEILING_QUALITY',
       'SKY_CEILING_DETERMINATION', 'SKY_CEILING_CAVOK_CODE',
       'VIS_DISTANCE_DIM', 'VIS_DISTANCE_QUALITY', 'VIZ_VARIABILITY',
       'VIZ_QUALITY_VARIABILITY', 'AIR_TEMP', 'AIR_TEMP_QUALITY', 'AIR_DEW',
       'AIR_DEW_QUALITY', 'ATM_PRESSURE', 'ATM_PRESSURE_QUALITY','KA1', 'KA2', 'MA1',
       'MD1', 'OC1', 'OD1']
frame=frame[cols_order]
frame.head()

```
<img src='Images/hourly_frame_expand.png' width='580' >


Load Station info

Create station_info table which contains only station details.Since we only have station no, their coordinates, name and country code, we need to add country name and create a station id which will be the primary key because station no is long int which is not good to be a primary key which takes more space.

```python 
# create station details df and add primary key using index
station_details=frame[['STATION','NAME','COUNTRY_CODE','LATITUDE','LONGITUDE']].drop_duplicates().reset_index(drop=True)
station_details['STATION_ID']=station_details.index+1
station_details=station_details[['STATION_ID','STATION','NAME','COUNTRY_CODE','LATITUDE','LONGITUDE']]

# read country list file 
c=open('additional_files/country_list.txt','r')
s=c.read()
country_list=s.split("\n")


# create two lists for code and name to store values from above list
country_code=[]
country_name=[]
n=0
for item in country_list:
    if n>1:
        s=item.replace(' ','')
        country_code.append(s[0:2])
        country_name.append(s[2:])
    n+=1

# create a df which can be used to join stations df
country_df=pd.DataFrame({'COUNTRY_CODE':country_code,
              'COUNTRY_NAME':country_name})


# get country name into the df doing a join on country_df
station_info=station_details.merge(country_df,on=['COUNTRY_CODE'],how='left')
station_info

```
<img src='Images/station_info_hourly.png' width='580' >


Connect to mysql server and the database

```python
# connect to mysql server and the database 
engine = create_engine('mysql+pymysql://root:password@localhost/weather_hourly')

# execute many which speeds up inserting to table process
@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(
       conn, cursor, statement, params, context, executemany
        ):
            if executemany:
                cursor.fast_executemany = True

```

Load station_info to `station_info` table using `to_sql` function

```python 
station_info.to_sql('stations_info',con = engine,if_exists='replace',index=False)
```

<img src='Images/station_info_load_hourly.png' width='580' >

Update Index

```python

update_index_sql='''CREATE UNIQUE INDEX station_id_location_index
ON weather_hourly.stations_info (station_id, longitude,latitude);'''

engine.execute(update_index_sql)

```

Load Zip codes info

We need zipcodes info for all places over the world because we donot have these info in our weather dataset, and it is very important attribute for our api.

```python
# read zipcodes info file
zipcodes=pd.read_csv('additional_files/geonames-postal.csv',on_bad_lines='skip',delimiter=';')
print("shape:",zipcodes.shape)
zipcodes.head()

```
<img src='Images/zip_codes_info_houlry.png' width='580' >

clean and tranform before loading to databse table

```python
# drop unnecessary columns
zipcodes=zipcodes.drop(['admin name3','admin code3','accuracy'],axis=1)

# rename columns
cols=['country_code','postal_code','place_name','state','state_code','county','county_code','latitude','longitude','coordinates']
zipcodes.columns=cols

zipcodes.head()
```
<img src='Images/zip_code_info_load_data_houlry.png' width='580' >

```python
# insert zipcodes to the table
zipcodes.to_sql('zipcodes_info',con = engine,if_exists='replace',index=False,schema="weather_hourly")

```
<img src='Images/zipcode_houlry_rows_loaded.png' width='580' >



Load Houlry Weather data

```python
# get station id from station_info
wdf=frame.merge(station_info[['STATION_ID','STATION']],right_on=['STATION'],left_on=['STATION'],how='left')

wdf=wdf[['STATION_ID','STATION', 'DATE', 'LATITUDE', 'LONGITUDE', 'NAME', 'COUNTRY_CODE',
       'WIND_DIRECTION_ANGLE', 'WIND_DIRECTION_QUALITY_CODE', 'WIND_TYPE_CODE',
       'WIND_SPEED_RATE', 'WIND_SPEED_QUALITY_CODE', 'SKY_CEILING_HEIGHT',
       'SKY_CEILING_QUALITY', 'SKY_CEILING_DETERMINATION',
       'SKY_CEILING_CAVOK_CODE', 'VIS_DISTANCE_DIM', 'VIS_DISTANCE_QUALITY',
       'VIZ_VARIABILITY', 'VIZ_QUALITY_VARIABILITY', 'AIR_TEMP',
       'AIR_TEMP_QUALITY', 'AIR_DEW', 'AIR_DEW_QUALITY', 'ATM_PRESSURE',
       'ATM_PRESSURE_QUALITY', 'KA1', 'KA2', 'MA1', 'MD1', 'OC1', 'OD1']]

# lowwer case all columns
wdf.columns=list(x.lower() for x in wdf.columns)
print("shape:",wdf.shape)

wdf.head(3)
```

```python
# check for duplicates because for a station and datetime there should be only one row
wdf[['station_id','date']].drop_duplicates().shape,wdf.shape
```

<img src='Images/hourly_weather_dup_check.png' width='580' >

Looks like there are duplicates

```python
# remove duplicates by keeping the first row
wdf = wdf.drop_duplicates(subset=['station_id', 'date'], keep='first')
wdf.shape

```
<img src='Images/after_remove_dup_hourly.png' width='580' >

```python
# insert weather data to a table 
wdf.to_sql('weather_info_2022_hourly',con = engine,if_exists='replace',index=False)

```

<img src='Images/weather_hourly_loaded_rows.png' width='580' >

Update Index

```python

update_index_sql='''CREATE UNIQUE INDEX station_id_date_index
ON weather_hourly.stations_info (station_id, date);'''

engine.execute(update_index_sql)

```


#### Load daily weather data

Import necessary packages

```python
import pandas as pd
import csv
import numpy as np
import glob
import os
from datetime import datetime
from sqlalchemy import create_engine
import pgeocode
from sqlalchemy import event
import swifter
import time
from pandarallel import pandarallel
import warnings

# Ignore all warnings
warnings.filterwarnings("ignore")
pd.set_option('display.max_columns', None)
pd.set_option('display.expand_frame_repr', False)

```

Lets take a look at the sample daily weather data file

```python
sample=pd.read_csv('station_files_daily/01001099999.csv')
sample.head(3)
```

<img src='Images/daily/daily_sample.png' width='580' >


Considering the data size ,we are not filtering the data by polygons here instead we are loading the weather data for all stations for the whole year 2022

We will follow the same steps as we did for loading houlry data.Iterate through 'station_files_daily' folder and read all files and concat to a data frame.

```python
files = glob.glob("/Users/rakeshkantharaju/Big_Data/Project/WeatherUS2022/station_files/*.csv")
required_cols=['STATION','DATE','LATITUDE','LONGITUDE','NAME','TEMP','WDSP','MXSPD','MAX','MIN','PRCP','FRSHTT']

fdf=[]
for file in files:
    df=pd.read_csv(file,index_col=None, header=0,dtype={'FRSHTT': object})
    fdf.append(df[required_cols])
    
frame = pd.concat(fdf, axis=0, ignore_index=True)
frame.head()
```

<img src='Images/daily/frame_daily.png' width='580' >

```python
# check if station numbers are unique in all files
print("Unique station count:",frame.STATION.nunique())
print("no of files:",len(files))
```

<img src='Images/daily/daily_stations_unique.png' width='580' >

Therefore, every csv file has unique station no

Handle datatypes and Transform the data

```python
# convert date to datetime
frame['DATE']=pd.to_datetime(frame['DATE'],format='mixed')

# create columns year, month, day from date columns
frame['YEAR']=frame['DATE'].apply(lambda x: x.year)
frame['MONTH']=frame['DATE'].apply(lambda x: x.month)
frame['DAY']=frame['DATE'].apply(lambda x: x.day)


# create station name and country columns seperately from name column
frame[['STATION_NAME','COUNTRY']]=frame['NAME'].str.split(', ',expand=True)
frame['COUNTRY']=frame['COUNTRY'].apply(lambda x: str(x)[-2:])
frame.head()

```

<img src='Images/daily/frame_after_clean.png' width='580' >

```python
# check for duplicates
frame.shape,frame.drop_duplicates().shape
```
<img src='Images/daily/dup_check_daily.png' width='580' >

Therefore, no duplicates

Insert stations_info

```python
# create station details df and add primary key using index
station_details=frame[['STATION','NAME','STATION_NAME','COUNTRY','LATITUDE','LONGITUDE']].drop_duplicates().reset_index(drop=True)
station_details['station_id']=station_details.index+1
station_details=station_details[['station_id','STATION','NAME','STATION_NAME','COUNTRY','LATITUDE','LONGITUDE']]

# read country list file 
c=open('additional_files/country_list.txt','r')
s=c.read()
country_list=s.split("\n")

# create two lists for code and name to store values from above list
country_code=[]
country_name=[]
n=0
for item in country_list:
    if n>1:
        s=item.replace(' ','')
        country_code.append(s[0:2])
        country_name.append(s[2:])
    n+=1

# create a df which can be used to join stations df
country_df=pd.DataFrame({'country_code':country_code,
              'country_name':country_name})

# get country name into the df doing a join on country_df
station_info=station_details.merge(country_df,left_on=['COUNTRY'],right_on=['country_code'],how='left')

# get only required columns and lower the column names 
station_info=station_info[['station_id','STATION','STATION_NAME','COUNTRY','country_name','LATITUDE','LONGITUDE']]
station_info.columns=['station_id','station_id_2','station_name','country_code','country_name','latitude','longitude']
station_info.head(3)

```

<img src='Images/daily/station_info_daily.png' width='580' >

```python
# check for duplicates

station_info[['station_id','latitude','longitude']].drop_duplicates().shape,station_info.shape

```

<img src='Images/daily/station_info_dup_check.png' width='580' >

There are suplicates, so remove duplicate rows

```python
station_info = station_info.drop_duplicates(subset=['station_id','latitude','longitude'], keep='first')
```
<img src='Images/daily/station_info_after_dup_check.png' width='580' >

Connect to MySQL server and weather database

```python
# connect to the database 
engine = create_engine('mysql+pymysql://root:password@localhost/weather')

@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(
       conn, cursor, statement, params, context, executemany
        ):
            if executemany:
                cursor.fast_executemany = True
```

```python
# insert the station info to the database
station_info.to_sql('stations_info',con = engine,if_exists='replace', index=False)
```

<img src='Images/daily/station_info_load_rows.png' width='580' >

Update Index

```python

update_index_sql='''CREATE UNIQUE INDEX station_id_location_index
ON weather.stations_info (station_id, longitude,latitude);'''

engine.execute(update_index_sql)

```

Load Zip Codes Info

```python
zipcodes=pd.read_csv('additional_files/geonames-postal.csv',on_bad_lines='skip',delimiter=';')

# drop unnecessary columns
zipcodes=zipcodes.drop(['admin name3','admin code3','accuracy'],axis=1)

# rename columns
cols=['country_code','postal_code','place_name','state','state_code','county','county_code','latitude','longitude','coordinates']
zipcodes.columns=cols

# insert zipcodes to the table
zipcodes.to_sql('zipcodes_info',con = engine,if_exists='replace',index=False)
```
<img src='Images/daily/zip_codes_load_rows.png' width='580' >

Insert weather data of every station

```python
# get station id
wdf=frame.merge(station_info[['station_id','station_id_2']],right_on=['station_id_2'],left_on=['STATION'],how='left')

# get required columns 
required_cols=['station_id','DATE','YEAR','MONTH','DAY','TEMP','WDSP','MXSPD','MAX','MIN','PRCP','FRSHTT']
wdf=wdf[required_cols]


# create columns for frshtt
wdf['fog']=wdf['FRSHTT'].apply(lambda x : '1' if x[0]=='1' else '0')
wdf['rain']=wdf['FRSHTT'].apply(lambda x : '1' if x[1]=='1' else '0')
wdf['snow']=wdf['FRSHTT'].apply(lambda x : '1' if x[2]=='1' else '0')
wdf['hail']=wdf['FRSHTT'].apply(lambda x : '1' if x[3]=='1' else '0')
wdf['thunder']=wdf['FRSHTT'].apply(lambda x : '1' if x[4]=='1' else '0')
wdf['tornado']=wdf['FRSHTT'].apply(lambda x : '1' if x[5]=='1' else '0')
wdf=wdf.drop('FRSHTT',axis=1)
wdf.head(3)

```

<img src='Images/daily/weather_daily_load.png' width='580' >

```python
# lower case all columns
wdf.columns=list(x.lower() for x in wdf.columns)

# check for duplicates
wdf.shape,wdf[['station_id','date']].drop_duplicates().shape

```
No duplicates found

```python
# insert weather data to a table 
wdf.to_sql('weather_info_2022',con = engine,if_exists='replace',index=False)

```
<img src='Images/daily/weather_daily_load_rows.png' width='580' >

Update Index

```python

update_index_sql='''CREATE UNIQUE INDEX station_id_date
ON weather.stations_info (station_id, date);'''

engine.execute(update_index_sql)

```

##### We have successfully laoded all weather datasets to the database tabels

### Build SQL queries to fetch data from database

I am going to explain important sql queries here, but you can have look at all the queries in 'sql_scripts' folder.

**get_nearest_stations.sql**

Returns nearest stations based on latitiude and longitude values and limits it by n rows.

```sql
select station_id,
station_name,
country_code,
latitude,
longitude,
distance
from
(
SELECT 
w.*,
2* atan2 ( sqrt(
                                sin(radians(latitude-(%s))/2) * 
                                sin(radians(latitude-(%s))/2) +
                                cos(radians(44.6592)) *
                                cos(radians(latitude)) *
                                sin(radians(longitude-(%s))/2) * 
                                sin(radians(longitude-(%s))/2) 
                                ),1-(
                                sin(radians(latitude-(%s))/2) * 
                                sin(radians(latitude-(%s))/2) +
                                cos(radians(44.6592)) *
                                cos(radians(latitude)) *
                                sin(radians(longitude-(%s))/2) * 
                                sin(radians(longitude-(%s))/2) 
) )as distance
FROM weather.stations_info as w
) as a
where distance is not null
ORDER BY distance limit %s;

```

**getData_by_station_id_by_date.sql**

Returns weather info of a given station and date

```sql
select 
w.*,
s.station_name 
from weather.weather_info_2022 as w
left join weather.stations_info as s on w.station_id =s.station_id 
where w.station_id=%s AND date=%s;
```

**getData_by_station_id_by_daterange.sql**

Returns weather info of a given station and date range

```sql
select 
w.*,
s.station_name 
from weather.weather_info_2022 as w
left join weather.stations_info as s on w.station_id =s.station_id 
where w.station_id=%s AND date between %s and %s;
```
**get_place_names.sql**

Get all the place names for a given zip code

```sql
select 
 distinct place_name
 from zipcodes_info
where postal_code=%s;
```

**get_place_coords.sql**

Considers all the locations for a given place zipcode and gets the lat and lon values for those.

```sql
select 
country_code,
place_name,
avg(latitude) as latitude ,
avg(longitude) as longitude  
from weather.zipcodes_info
where lower(place_name) LIKE %s and lower(country_code)= %s
group by 1,2;
```

**get_data_by_zip_by_date.sql**

Given a location's latitude and longitude value, it calcualates the distance between the given location and all the stations and considers the nearest station and fetches all the weather details of that station for the given date.This is the common mechanism for most of the queries to get the weather data for a given location.

```sql
select w.*,
                    ns.station_name,
                    ns.distance,
                    ns.country_name,
                    ns.latitude,
                    ns.longitude
                    from
                    (
                                select station_id,
                                station_name,
                                distance,
                                country_name,
                                latitude,
                                longitude
                                from
                                (
                                SELECT 
                                station_id,
                                station_name,
                                country_name,
                                latitude,
                                longitude,
                                2* atan2 ( sqrt(
                                sin(radians(latitude-(%s))/2) * 
                                sin(radians(latitude-(%s))/2) +
                                cos(radians(44.6592)) *
                                cos(radians(latitude)) *
                                sin(radians(longitude-(%s))/2) * 
                                sin(radians(longitude-(%s))/2) 
                                ),1-(
                                sin(radians(latitude-(%s))/2) * 
                                sin(radians(latitude-(%s))/2) +
                                cos(radians(44.6592)) *
                                cos(radians(latitude)) *
                                sin(radians(longitude-(%s))/2) * 
                                sin(radians(longitude-(%s))/2) 
                                ) )as distance
                                FROM stations_info
                                ) as a
                                where distance is not null
                                ORDER BY distance limit 1
                    ) as ns
                    inner join 
                    (
                            select * from weather_info_2022
                            where date=%s
                    ) as w 
                    on ns.station_id=w.station_id;
```


### Build Weather API

We are builing the api in python file rathar on ipynb because we are going to run the api as a whole script.

*api.py*


Import required packages

```python
import csv
import pandas as pd
import datetime
from datetime import datetime
import requests,json
import json,pymysql,time
from flask import Flask
from flask import request,redirect,render_template,session
import datetime
import folium
import os
```

Config the database connection


```python
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'password',
    'database': 'weather',
    'autocommit':True
}

conn=pymysql.connect(**db_config)
cur = conn.cursor(pymysql.cursors.DictCursor)
```

creating a function `get_frshtt` to return frshtt values which will be used in out api

```python
def get_frshtt(row):
    frshtt={'fog':0,
            'rain':0,
            'snow':0,
            'hail':0,
            'thunder':0,
            'tornado':0
            }
    if row['fog']=='1':
        frshtt['fog']=1
    if row['rain']=='1':
        frshtt['rain']=1
    if row['snow']=='1':
        frshtt['snow']=1
    if row['hail']=='1':
        frshtt['hail']=1
    if row['thunder']=='1':
        frshtt['thunder']=1
    if row['tornado']=='1':
        frshtt['tornado']=1
    return frshtt
```


Create a Flask web application instance named `app` and create a route for the root URL ("/") that can handle both GET and POST requests.

```python
app=Flask(__name__)

@app.route("/",methods=["GET","POST"])
def root():
    res={}
    res['code']=1
    res['msg']='No Endpoint specified'
    res['req']='/'
    return json.dumps(res,indent=4)
```
Lets begin with our first enpoint


------------------------------------------------------
**get_nearest_stations**

Sometimes user might not know the exact place name or zip code, or the zip code's lat lon value might be far away from the place where user is looking for, therefore this end point will give `n` nearest stations detail based on users latitude and longitude values

endpoint example : http://10.2.3.251:5000/get_nearest_stations?key=123&lat=44.6592&lon=-74.9681&n=15

```python
@app.route("/get_nearest_stations",methods=['GET','POST'])
def get_nearest_stations():
    res={}
    
    # get key and check if key value is 123 else return Invalid key
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    

    lat=request.args.get("lat") # recieve latitude value from user input
    lon=request.args.get("lon") # recieve longitude value from user input
    n=request.args.get("n") # recieve number of stations from user input

    # try converting lat lon values to float , and n to int
    # any error in the above return invalid entry
    try:
        latitude=float(lat)
        longitude=float(lon)
        n=int(n)
    except:
        res['code']=0
        res['msg']='Invalid entry'
        return json.dumps(res,indent=4)
    
    # once lat lon and n values are received properly then pass these values 
    # to the sql which runs on MySQL and returns the output
    # reads the sql query from sql_scripts folder
    get_zip_coords_sql=open('sql_scripts/get_nearest_stations.sql').read()
    start_time=time.time()
    # exceute the query 
    cur.execute(get_zip_coords_sql,(latitude,latitude,
                                 longitude,longitude,
                                 latitude,latitude,
                                 longitude,longitude,
                                 n))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    # create a list to store all the results
    output=[]
    # iterate through all the rows and extract the required outputs and store it in dictionary 'item'.
    for row in cur:
        item={}
        item['station_id']=str(row['station_id'])
        item['station_name']=str(row['station_name'])
        item['country_code']=str(row['country_code'])
        item['latitude']=str(row['latitude'])
        item['longitude']=str(row['longitude'])
        item['station_distance']=str(round(row['distance'],2))+" m"
        output.append(item)

    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/get_nearest_stations'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/get_nearest_stations.png' width='580' >

--------------------------------------------------------------------

**getTableData_nearest_stations**

This endpoint allows user to look at nearest stations data for a given lat and lon values in tablular format.\
You can search by rows, sort and download the data to csv.

endpoint example : http://10.2.3.251:5000/getTableData_nearest_stations?key=123&lat=44.6592&lon=-74.9681&n=5

```python
@app.route("/getTableData_nearest_stations",methods=['GET','POST'])
def getTableData_nearest_stations():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    lat=request.args.get("lat")
    lon=request.args.get("lon")
    n=request.args.get("n")
    # print(given_date,given_zip)
    try:
        latitude=float(lat)
        longitude=float(lon)
        n=int(n)
    except:
        res['code']=0
        res['msg']='Invalid entry'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_nearest_stations.sql').read()
    start_time=time.time()
    cur.execute(get_zip_coords_sql,(latitude,latitude,
                                 longitude,longitude,
                                 latitude,latitude,
                                 longitude,longitude,
                                 n))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    row_df=pd.DataFrame(cur.fetchall())
    res['sql_time']=round(end_time-start_time,2)
    res['req']='/getTableData_nearest_stations'
    df=row_df.reset_index().drop('index',axis=1)
    
    table_html = df.to_html(classes='table table-bordered table-striped', index=False)

    return render_template('table3.html', df=df,n = df.shape[0],file_name='nearest_stations')
```

<img src='Images/api_outputs/getTableData_nearest_stations.png' width='580' >

--------------------------------------------------------------------

**getData_by_station_id_by_date**

Once the user has the stations details using the above endpoint, can use this endpoint to look at weather data for a given station id and date.

endpoint example : http://10.2.3.251:5000/getData_by_station_id_by_date?key=123&station_id=2473&date=2022-01-01

```python
@app.route("/getData_by_station_id_by_date",methods=['GET','POST'])
def getData_by_station_id_by_date():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    station_id=request.args.get("station_id")
    given_date=request.args.get("date")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
        station_id=int(station_id)

    except:
        res['code']=0
        res['msg']='Invalid entry'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/getData_by_station_id_by_date.sql').read()
    start_time=time.time()
    cur.execute(get_zip_coords_sql,(station_id,user_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    for row in cur:
        item={}
        item['station_name']=str(row['station_name'])
        item['year']=str(row['year'])
        item['month']=str(row['month'])
        item['weather']={}
        item['weather']['temp']={}
        item['weather']['temp']['mean_temp']=str(row['temp'])
        item['weather']['temp']['max_temp']=str(row['max'])
        item['weather']['temp']['min_temp']=str(row['min'])
        item['weather']['wind_speed']=str(row['wdsp'])
        item['weather']['precipitation']=str(row['prcp'])
        item['weather']['max_wind']=str(row['mxspd'])
        item['weather']['frshtt']=get_frshtt(row)
        output.append(item)

    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_station_id_by_date'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getData_by_station_by_date.png' width='580' >


--------------------------------------------------------------------

**getData_by_station_id_by_daterange**

Similar to last endpoint , but user can view weather data for a given station and given date range

endpoint example : http://10.2.3.251:5000/getData_by_station_id_by_daterange?key=123&station_id=2473&start_date=2022-01-01&end_date=2022-01-02

```python
@app.route("/getData_by_station_id_by_daterange",methods=['GET','POST'])
def getData_by_station_id_by_daterange():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    station_id=request.args.get("station_id")
    start_date=request.args.get("start_date")
    end_date=request.args.get("end_date")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        start_date=datetime.datetime.strptime(start_date,date_format)
        end_date=datetime.datetime.strptime(end_date,date_format)
        station_id=int(station_id)

    except:
        res['code']=0
        res['msg']='Invalid entry'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_data_by_station_id_by_daterange.sql').read()
    start_time=time.time()
    cur.execute(get_zip_coords_sql,(station_id,start_date,end_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    n=0
    item={}
    item['weather']={}
    item['weather']['dates']={}
    for row in cur:
        # print(row)
        if n==0:
            item['station_name']=str(row['station_name'])
            item['year']=str(row['year'])
            item['month']=str(row['month'])
        date=str(row['date'])
        item['weather']['dates'][date]={}
        item['weather']['dates'][date]['temp']={}
        item['weather']['dates'][date]['temp']['mean_temp']=str(row['temp'])
        item['weather']['dates'][date]['temp']['max_temp']=str(row['max'])
        item['weather']['dates'][date]['temp']['min_temp']=str(row['min'])
        item['weather']['dates'][date]['wind_speed']=str(row['wdsp'])
        item['weather']['dates'][date]['precipitation']=str(row['prcp'])
        item['weather']['dates'][date]['frshtt']=get_frshtt(row)
        n+=1

    output.append(item)

    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_station_id_by_daterange'
    return json.dumps(res,indent=4)
```
<img src='Images/api_outputs/getData_by_station_by_daterange.png' width='580' >

-------------------------------------------------

**getTableData_by_station_id_by_daterange**

Similar to last endpoint , but user can view weather data for a given station and given date range in a tabular format

endpoint example : http://10.2.3.251:5000/getTableData_by_station_id_by_daterange?key=123&station_id=2473&start_date=2022-01-01&end_date=2022-01-02


```python
@app.route("/getTableData_by_station_id_by_daterange",methods=['GET','POST'])
def getTableData_by_station_id_by_daterange():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    station_id=request.args.get("station_id")
    start_date=request.args.get("start_date")
    end_date=request.args.get("end_date")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        start_date=datetime.datetime.strptime(start_date,date_format)
        end_date=datetime.datetime.strptime(end_date,date_format)
        station_id=int(station_id)

    except:
        res['code']=0
        res['msg']='Invalid entry'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_data_by_station_id_by_daterange.sql').read()
    start_time=time.time()
    cur.execute(get_zip_coords_sql,(station_id,start_date,end_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    
    row_df=pd.DataFrame(cur.fetchall())
    res['sql_time']=round(end_time-start_time,2)
    res['req']='/getTableData_by_station_id_by_daterange'
    df=row_df.reset_index().drop('index',axis=1)
    
    table_html = df.to_html(classes='table table-bordered table-striped', index=False)

    return render_template('table3.html', df=df,n = df.shape[0],file_name='weatherdata_by_station_by_daterange')
```

<img src='Images/api_outputs/getTabledata_by_station_by_daterange.png' width='580' >

---------------------

**getData_by_zip_by_date**

Allows you to view weather data for a given zip for a given date

endpoint example : http://10.2.3.251:5000/getData_by_zip_by_date?key=123&zipcode=13676&date=2022-01-01

```python
@app.route("/getData_by_zip_by_date",methods=['GET','POST'])
def getData_by_zip_by_date():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")
    given_zip=request.args.get("zipcode")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        # print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_date.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 user_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    for row in cur:
        item={}
        item['station_name']=str(row['station_name'])
        item['station_distance']=str(round(row['distance'],2))+" m"
        item['year']=str(row['year'])
        item['month']=str(row['month'])
        item['weather']={}
        item['weather']['temp']={}
        item['weather']['temp']['mean_temp']=str(row['temp'])
        item['weather']['temp']['max_temp']=str(row['max'])
        item['weather']['temp']['min_temp']=str(row['min'])
        item['weather']['wind_speed']=str(row['wdsp'])
        item['weather']['precipitation']=str(row['prcp'])
        item['weather']['max_wind']=str(row['mxspd'])
        item['weather']['frshtt']=get_frshtt(row)
        output.append(item)

    res['places_under_zipcode']=place_names
    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_zip_by_date'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getData_by_zip_by_date.png' width='580' >

-----------

**getData_by_zip_by_daterange**

Allows you to view weather data for a given zip for a given date range

endpoint example : http://10.2.3.251:5000/getData_by_zip_by_daterange?key=123&zipcode=13676&start_date=2022-01-01&end_date=2022-01-03

```python

@app.route("/getData_by_zip_by_daterange",methods=['GET','POST'])
def getData_by_zip_by_daterange():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    start_date=request.args.get("start_date")
    end_date=request.args.get("end_date")
    given_zip=request.args.get("zipcode")
    date_format="%Y-%m-%d"
    try:
        start_date=datetime.datetime.strptime(start_date,date_format)
        end_date=datetime.datetime.strptime(end_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_daterange.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 start_date,end_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    n=0
    item={}
    item['weather']={}
    item['weather']['dates']={}
    for row in cur:
        # print(row)
        if n==0:
            item['station_name']=str(row['station_name'])
            item['station_distance']=str(round(row['distance'],2))+" m"
            item['year']=str(row['year'])
            item['month']=str(row['month'])
        date=str(row['date'])
        item['weather']['dates'][date]={}
        item['weather']['dates'][date]['temp']={}
        item['weather']['dates'][date]['temp']['mean_temp']=str(row['temp'])
        item['weather']['dates'][date]['temp']['max_temp']=str(row['max'])
        item['weather']['dates'][date]['temp']['min_temp']=str(row['min'])
        item['weather']['dates'][date]['wind_speed']=str(row['wdsp'])
        item['weather']['dates'][date]['precipitation']=str(row['prcp'])
        item['weather']['dates'][date]['frshtt']=get_frshtt(row)
        n+=1

    output.append(item)

    res['places_under_zipcode']=place_names
    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)

    res['req']='/getData_by_zip_by_daterange'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getData_by_zip_by_daterange.png' width='580' >

------

**getTableData_by_zip_by_daterange**

Allows you to view weather data for a given zip for a given date range in html tabular format with few view options.

endpoint example : http://10.2.3.251:5000/getTableData_by_zip_by_daterange?key=123&zipcode=13676&start_date=2022-01-01&end_date=2022-01-10


```python
@app.route("/getTableData_by_zip_by_daterange",methods=['GET','POST'])
def getTableData_by_zip_by_daterange():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    start_date=request.args.get("start_date")
    end_date=request.args.get("end_date")
    given_zip=request.args.get("zipcode")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        start_date=datetime.datetime.strptime(start_date,date_format)
        end_date=datetime.datetime.strptime(end_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        # print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_daterange.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 start_date,end_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    row_df=pd.DataFrame(cur.fetchall())
    row_df['place']=place_names[0]

    res['num_results']=row_df.shape[0]
    res['sql_time']=round(end_time-start_time,2)

    res['req']='/getTableData_by_zip_by_daterange'

    df=row_df.reset_index().drop('index',axis=1)
    
    table_html = df.to_html(classes='table table-bordered table-striped', index=False)

    return render_template('table3.html', df=df,n = df.shape[0],file_name='weatherdata_by_zip_by_daterange')
```

<img src='Images/api_outputs/getTableData_by_zip_by_daterange.png' width='580' >

------

**getData_by_placename_by_date**

Allows you to view weather data for a given placename for a given date

endpoint example : http://10.2.3.251:5000/getData_by_placename_by_date?key=123&place_name=potts&country_code=us&date=2022-01-01

```python
@app.route("/getData_by_placename_by_date",methods=['GET','POST'])
def getData_by_placename_by_date():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")

    given_place=request.args.get("place_name")
    given_place=f'{given_place.lower()}%'
    # print(given_place)

    given_country_code=request.args.get("country_code")
    given_country_code=given_country_code.lower()

    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    

    get_zip_coords_sql=open('sql_scripts/get_place_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_place,given_country_code))

    coordinates={}
    for row in cur:
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Place name doesn\'t match with any'
            return json.dumps(res,indent=4)
        else:
            p=row['place_name']
            coordinates[p]={}
            coordinates[p]['latitude']=float(row['latitude'])
            coordinates[p]['longitude']=float(row['longitude'])

    records=[]
    for place,coords in coordinates.items():
        latitude=coords['latitude']
        longitude=coords['longitude']

        get_weather_sql=open('sql_scripts/get_data_by_zip_by_date.sql').read()
        start_time=time.time()
        cur.execute(get_weather_sql,(latitude,latitude,
                                    longitude,longitude,
                                    latitude,latitude,
                                    longitude,longitude,
                                    user_date))
        end_time=time.time()
        

        res['code']=1
        res['msg']='ok'

        output=[]
        for row in cur:
            item={}
            item['place_name']=place
            item['station_name']=str(row['station_name'])
            item['station_distance']=str(round(row['distance'],2))+" m"
            item['year']=str(row['year'])
            item['month']=str(row['month'])
            item['weather']={}
            item['weather']['temp']={}
            item['weather']['temp']['mean_temp']=str(row['temp'])
            item['weather']['temp']['max_temp']=str(row['max'])
            item['weather']['temp']['min_temp']=str(row['min'])
            item['weather']['wind_speed']=str(row['wdsp'])
            item['weather']['precipitation']=str(row['prcp'])
            item['weather']['max_wind']=str(row['mxspd'])
            item['weather']['frshtt']=get_frshtt(row)
            output.append(item)

        records.append(output)
        
    res['results']=records
    res['num_results']=len(records)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_placename_by_date'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getdata_by_placename.png' width='580' >

-------

**getTableData_by_placename_by_date**

Allows you to view weather data for a given placename for a given date

endpoint example : http://10.2.3.251:5000/getTableData_by_placename_by_date?key=123&place_name=potts&country_code=us&date=2022-01-01

```python
@app.route("/getTableData_by_placename_by_date",methods=['GET','POST'])
def getTableData_by_placename_by_date():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")

    given_place=request.args.get("place_name")
    given_place=f'{given_place.lower()}%'
    # print(given_place)

    given_country_code=request.args.get("country_code")
    given_country_code=given_country_code.lower()

    date_format="%Y-%m-%d"

    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)

    get_zip_coords_sql=open('sql_scripts/get_place_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_place,given_country_code))

    coordinates={}

    for row in cur:
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Place name doesn\'t match with any'
            return json.dumps(res,indent=4)
        else:
            p=row['place_name']
            coordinates[p]={}
            coordinates[p]['latitude']=float(row['latitude'])
            coordinates[p]['longitude']=float(row['longitude'])
    # print(coordinates)
    records=[]
    cols=['station_id','date',
                                  'year',
                                  'month',
                                  'day',
                                  'mean_temp',
                                  'wind_speed',
                                  'max_wind_speed',
                                  'max_temp',
                                  'min_temp',
                                  'precipitation',
                                  'fog',
                                  'rain',
                                  'snow',
                                  'hail',
                                  'thunder',
                                  'tornado',
                                  'station_name',
                                  'station-distance',
                                  'country_name',
                                  'latitude',
                                  'longitude',
                                  'place_name'
                                  ]
    df=pd.DataFrame()
    for place,coords in coordinates.items():
        latitude=coords['latitude']
        longitude=coords['longitude']

        get_weather_sql=open('sql_scripts/get_data_by_zip_by_date.sql').read()
        start_time=time.time()
        cur.execute(get_weather_sql,(latitude,latitude,
                                    longitude,longitude,
                                    latitude,latitude,
                                    longitude,longitude,
                                    user_date))
        end_time=time.time()
        row_df=pd.DataFrame(cur.fetchall())
        if not row_df.empty:
            row_df['place_name']=place
            row_df.columns=cols
            df=pd.concat([df,row_df],ignore_index=True)
            a=cols[:-1]
            a.insert(0,cols[-1])
            df=df[a]
        
    res['num_results']=df.shape[0]
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getTableData_by_placename_by_date'
    df=df.reset_index().drop('index',axis=1)
    
    table_html = df.to_html(classes='table table-bordered table-striped', index=False)
    return render_template('table3.html', df=df, n =df.shape[0],file_name='weatherdata_by_place_by_date')
```

<img src='Images/api_outputs/getTabledata_by_place_by_date.png' width='580' >

-----

**getData_by_zip_by_date_by_hour**

Allows you to view weather data for a given zipcode for a given hour for the given date

endpoint example : http://10.2.3.251:5000/getData_by_zip_by_date_by_hour?key=123&zipcode=13676&date=2022-01-01&hour=13

```python
@app.route("/getData_by_zip_by_date_by_hour",methods=['GET','POST'])
def getData_by_zip_by_date_by_hour():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")
    given_zip=request.args.get("zipcode")
    given_hour=int(request.args.get('hour'))
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    
    if not ((given_hour >=0 and given_hour <24)):
        res['code']=0
        res['msg']='Invalid hour'
        return json.dumps(res,indent=4)

    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        # print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_date_by_hour.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 user_date,given_hour))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    item={}
    wd=[]
    ws=[]
    wv=[]
    wat=[]
    wap=[]
    for row in cur:
        
        item['station_name']=str(row['station_name'])
        item['station_distance']=str(round(row['distance'],2))+" m"
        item['year']=str(row['given_year'])
        item['month']=str(row['month_of_year'])
        item['week']=str(row['week_of_month'])
        item['hour']=str(row['hour_of_day'])
        item['weather']={}


        item['weather']['wind']={}
        wd=list(set(wd + [str(row['wind_direction_angle'])]))
        item['weather']['wind']['direction']=wd
        item['weather']['wind']['direction_quality']=str(row['wind_direction_quality_code'])
        item['weather']['wind']['type_code']=str(row['wind_type_code'])
        item['weather']['wind']['speed_rate']=str(row['wind_speed_rate'])
        item['weather']['wind']['speed_quality']=str(row['wind_speed_quality_code'])
        item['weather']['wind']['units']={}
        item['weather']['wind']['units']['direction']='Angular Degrees'
        item['weather']['wind']['units']['speed_rate']='meters per second'


        item['weather']['sky']={}
        ws=list(set(ws + [str(row['sky_ceiling_height'])]))
        item['weather']['sky']['ceiling_height']=ws
        item['weather']['sky']['ceiling_quality']=str(row['sky_ceiling_quality'])
        item['weather']['sky']['ceiling_determination']=str(row['sky_ceiling_determination'])
        item['weather']['sky']['ceiling_cavok_code']=str(row['sky_ceiling_cavok_code'])
        item['weather']['sky']['units']={}
        item['weather']['sky']['units']['ceiling height']='meters'


        item['weather']['visibility']={}
        wv=list(set(wv + [str(row['vis_distance_dim'])]))
        item['weather']['visibility']['distance_dimension']=wv
        item['weather']['visibility']['distance_quality']=str(row['vis_distance_quality'])
        item['weather']['visibility']['variability']=str(row['viz_variability'])
        item['weather']['visibility']['quality_variability']=str(row['viz_quality_variability'])
        item['weather']['visibility']['units']={}
        item['weather']['visibility']['units']['distance_dimension']='meters'

        item['weather']['air_temperature']={}
        wat=list(set(wat + [str(row['air_temp'])]))
        item['weather']['air_temperature']['temperature']=wat
        item['weather']['air_temperature']['temp_quality']=str(row['air_temp_quality'])
        item['weather']['air_temperature']['dew_point_temp']=str(row['air_dew'])
        item['weather']['air_temperature']['dew_qulity']=str(row['air_dew_quality'])
        item['weather']['air_temperature']['units']={}
        item['weather']['air_temperature']['units']['temperature']='Degrees Celsius'
        item['weather']['air_temperature']['units']['dew_point_temp']='Degrees Celsius'

        item['weather']['atmospheric_presure']={}
        wap=list(set(wap + [str(row['atm_pressure'])]))
        item['weather']['atmospheric_presure']['sea_level_pressure']=wap
        item['weather']['atmospheric_presure']['quality']=str(row['atm_pressure_quality'])
        item['weather']['atmospheric_presure']['units']={}
        item['weather']['atmospheric_presure']['units']['sea_level_pressure']='Hectopascals'

    output.append(item)

    res['places_under_zipcode']=place_names
    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_zip_by_date_by_hour'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getData_by_zip_by_date_by_hour.png' width='580' >

----

**getData_by_zip_by_date_all_hours**

Allows you to view weather data for a given zipcode for a given all hours for the given date

endpoint example : http://10.2.3.251:5000/getData_by_zip_by_date_all_hours?key=123&zipcode=13676&date=2022-01-01

```python
@app.route("/getData_by_zip_by_date_all_hours",methods=['GET','POST'])
def getData_by_zip_by_date_all_hours():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")
    given_zip=request.args.get("zipcode")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    


    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        # print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_date_all_hours.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 user_date))
    end_time=time.time()
    

    res['code']=1
    res['msg']='ok'

    output=[]
    item={}
    n=0
    for row in cur:
        if n==0:
            item['station_name']=str(row['station_name'])
            item['station_distance']=str(round(row['distance'],2))+" m"
            item['year']=str(row['given_year'])
            item['hour']=[]
            d={}
            item['hour'].append(d)
        
        hr=str(row['hour_of_day'])
        item['hour'][0][hr]={}
        item['hour'][0][hr]['weather']={}
        item['hour'][0][hr]['weather']['wind']={}
        item['hour'][0][hr]['weather']['wind']['direction']=str(row['avg_wind_direction_angle'])
        item['hour'][0][hr]['weather']['wind']['speed_rate']=str(row['avg_wind_speed_rate'])
        item['hour'][0][hr]['weather']['wind']['units']={}
        item['hour'][0][hr]['weather']['wind']['units']['direction']='Angular Degrees'
        item['hour'][0][hr]['weather']['wind']['units']['speed_rate']='meters per second'


        item['hour'][0][hr]['weather']['sky']={}
        item['hour'][0][hr]['weather']['sky']['ceiling_height']=str(row['avg_sky_ceiling_height'])
        item['hour'][0][hr]['weather']['sky']['units']={}
        item['hour'][0][hr]['weather']['sky']['units']['ceiling height']='meters'


        item['hour'][0][hr]['weather']['visibility']={}
        item['hour'][0][hr]['weather']['visibility']['distance_dimension']=str(row['avg_vis_distance'])
        item['hour'][0][hr]['weather']['visibility']['units']={}
        item['hour'][0][hr]['weather']['visibility']['units']['distance_dimension']='meters'

        item['hour'][0][hr]['weather']['air_temperature']={}
        item['hour'][0][hr]['weather']['air_temperature']['temperature']=str(row['avg_air_temp'])
        item['hour'][0][hr]['weather']['air_temperature']['dew_point_temp']=str(row['avg_air_dew'])
        item['hour'][0][hr]['weather']['air_temperature']['units']={}
        item['hour'][0][hr]['weather']['air_temperature']['units']['temperature']='Degrees Celsius'
        item['hour'][0][hr]['weather']['air_temperature']['units']['dew_point_temp']='Degrees Celsius'

        item['hour'][0][hr]['weather']['atmospheric_presure']={}
        item['hour'][0][hr]['weather']['atmospheric_presure']['sea_level_pressure']=str(row['avg_atm_pressure'])
        item['hour'][0][hr]['weather']['atmospheric_presure']['units']={}
        item['hour'][0][hr]['weather']['atmospheric_presure']['units']['sea_level_pressure']='Hectopascals'
        n+=1

    output.append(item)

    res['places_under_zipcode']=place_names
    res['results']=output
    res['num_results']=len(output)
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getData_by_zip_by_date_all_hours'
    return json.dumps(res,indent=4)
```

<img src='Images/api_outputs/getData_by_zip_by_date_all_hours.png' width='580' >

----

**getTableData_by_zip_by_date_all_hours**

Allows you to view previous endpoint weather data for a given zipcode for a given all hours for the given date in a html tabular format with other view option like sort, search and download.

endpoint example : http://10.2.3.251:5000/getTableData_by_zip_by_date_all_hours?key=123&zipcode=13676&date=2022-01-01

```python
@app.route("/getTableData_by_zip_by_date_all_hours",methods=['GET','POST'])
def getTableData_by_zip_by_date_all_hours():
    res={}
    
    key=request.args.get("key")
    if key!='123':
        res['code']=0
        res['msg']='Invalid key'
        return json.dumps(res,indent=4)
    
    given_date=request.args.get("date")
    given_zip=request.args.get("zipcode")
    date_format="%Y-%m-%d"
    # print(given_date,given_zip)
    try:
        user_date=datetime.datetime.strptime(given_date,date_format)
    except:
        res['code']=0
        res['msg']='Invalid date'
        return json.dumps(res,indent=4)
    


    get_zip_coords_sql=open('sql_scripts/get_zip_coords.sql').read()
    cur.execute(get_zip_coords_sql,(given_zip))
    for row in cur:
        # print(row['latitude'])
        if (row['latitude'] == None) or (row['longitude'] == None):
            res['code']=0
            res['msg']='Invalid Zip Code'
            return json.dumps(res,indent=4)
        else:
            zip_latitude=float(row['latitude'])
            zip_longitude=float(row['longitude'])

    get_place_names_sql=open('sql_scripts/get_place_names.sql').read()
    cur.execute(get_place_names_sql,(given_zip))
    place_names=[]
    for row in cur:
        place_names.append(row['place_name'])

    get_weather_sql=open('sql_scripts/get_data_by_zip_by_date_all_hours.sql').read()
    start_time=time.time()
    cur.execute(get_weather_sql,(zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 zip_latitude,zip_latitude,
                                 zip_longitude,zip_longitude,
                                 user_date))
    end_time=time.time()

    df=pd.DataFrame()

    row_df=pd.DataFrame(cur.fetchall())
    if not row_df.empty:
        row_df['zipcode']=place_names[0]
        df=pd.concat([df,row_df],ignore_index=True)
        
    res['num_results']=df.shape[0]
    res['sql_time']=round(end_time-start_time,2)
    
    res['req']='/getTableData_by_zip_by_date_all_hours'
    df=df.reset_index().drop('index',axis=1)
    
    table_html = df.to_html(classes='table table-bordered table-striped', index=False)
    return render_template('table3.html', df=df, n =df.shape[0],file_name='weatherdata_by_zip_by_date_all_hours')
```

<img src='Images/api_outputs/getTableData_by_zip_by_date_all_hours.png' width='580' >

------

Finally the below code starts a Flask web application on IP address '10.2.3.251' with debugging enabled if the script is run directly.

```python
if __name__=='__main__':
    app.run(host='10.2.3.251',debug=True)
```


