select 
w.*,
s.station_name 
from weather.weather_info_2022 as w
left join weather.stations_info as s on w.station_id =s.station_id 
where w.station_id=%s AND date between %s and %s;