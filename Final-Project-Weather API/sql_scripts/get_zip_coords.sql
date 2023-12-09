select 
avg(latitude) as latitude ,
avg(longitude) as longitude  
from zipcodes_info
where postal_code=%s;