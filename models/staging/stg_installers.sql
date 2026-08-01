with source as (
    select * from {{ ref('raw_installers') }}
)

select
    installer_id,
    installer_name,
    hardware_type,
    country,
    cast(signup_date as date) as signup_date
from source
