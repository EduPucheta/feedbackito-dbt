
{{ config(materialized='view') }}

with source as (
 
    select * from {{ source('raw', 'profiles') }}
    -- Drop Fivetran soft-deleted rows. A 2026-07-31 re-sync left a deleted twin
    -- next to the live row for some ids, which broke uniqueness of user_id.
    where not coalesce(_fivetran_deleted, false)

),
   
 renamed as (
 
    select 
        id as user_id,
        name, 
        email,
        image,
      
     
        has_access,
  
        plan,  
        _fivetran_deleted 

    from source 

)

select * from renamed
 