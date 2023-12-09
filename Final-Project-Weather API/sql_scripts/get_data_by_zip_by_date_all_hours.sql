select w.*,
                    ns.name as station_name,
                    ns.distance,
                    ns.country_name
                    from
                    (
                                select station_id,
                                name,
                                distance,
                                country_name
                                from
                                (
                                SELECT 
                                station_id,
                                name,
                                country_name,
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
                                FROM weather_hourly.stations_info
                                ) as a
                                where distance is not null
                                ORDER BY distance limit 1
                    ) as ns
                    inner join 
                    (
												select 
												station_id,
												user_date,
												given_year,
												hour_of_day,
												round(avg(case when wind_direction_angle <> 'missing' then wind_direction_angle end),2) as avg_wind_direction_angle,
												round(avg(case when wind_speed_rate <> 'missing' then wind_speed_rate end),2) as avg_wind_speed_rate,
												round(avg(case when sky_ceiling_height <> 'missing' then sky_ceiling_height end),2) as avg_sky_ceiling_height,
												round(avg(case when vis_distance_dim <> 'missing' then vis_distance_dim end),2) as avg_vis_distance,
												round(avg(case when air_temp <> 'missing' then air_temp end),2) as avg_air_temp,
												round(avg(case when air_dew <> 'missing' then air_dew end),2) as avg_air_dew,
												round(avg(case when atm_pressure <> 'missing' then atm_pressure end),2) as avg_atm_pressure
												from
                    							(
														 select 
														 station_id,
														 date(date) as user_date,
														 year(date) as given_year,
														 hour(date) as hour_of_day,
														 case when wind_direction_angle=999 then 'missing' else wind_direction_angle end as wind_direction_angle,
														 case when wind_speed_rate =9999 then 'missing' else wind_speed_rate end as wind_speed_rate,
														 case when sky_ceiling_height=99999 then 'missing' else sky_ceiling_height end as sky_ceiling_height,
														 case when vis_distance_dim=999999 then 'missing' else vis_distance_dim end as vis_distance_dim,
														 case when air_temp='+9999' then 'missing' else air_temp end as air_temp,
														 case when air_dew='+9999' then 'missing' else air_dew end as air_dew,
														 case when atm_pressure=99999 then 'missing' else atm_pressure end as atm_pressure
														from weather_hourly.weather_info_2022_hourly
								                            where date(date)= %s
						                         ) as x
						                         group by 1,2,3,4
                    ) as w 
                    on ns.station_id=w.station_id;