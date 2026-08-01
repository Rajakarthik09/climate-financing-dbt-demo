select
    installer_id,
    installer_name,
    hardware_type,
    country,
    signup_date
from {{ ref('stg_installers') }}
