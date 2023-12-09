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