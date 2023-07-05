{{ config( 
        materialized = "incremental", 
        unique_key = "Date"
) }}

with orders_view as (

    {#-
    Normally we would select from the table here, but we are using staging to load
    our data in this project
    #}
    select * from {{ ref('stg_orders') }}

),

payments_view as (
    select * from {{ ref('stg_payments') }}
),

monthly_rev as (

    SELECT 
        strftime('%Y-%m', order_date) AS "Date", 
        strftime('%Y-%m', order_date) AS "event_time",
        sum(amount) AS "Monthly Revenue"
    
    FROM  orders_view join payments_view on orders_view.order_id = payments_view.order_id
    AND "status" NOT IN ('return_pending', 'returned')

    WHERE "event_time" < strftime('%Y-%m', datetime('now'))
    
    GROUP BY Date

)

select * from monthly_rev


{% if is_incremental() %}
--   this filter will only be applied on an incremental run

  WHERE event_time > (select max(event_time) from {{ this }}) 
  AND strftime('%Y-%m', event_time) < strftime('%Y-%m', datetime('now'))

{% else %}
  -- this will run on a full-refresh

  WHERE event_time < strftime('%Y-%m', datetime('now'))

{% endif %}
