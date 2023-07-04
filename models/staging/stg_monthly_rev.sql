{{config({"materialized" : "incremental"}
)}}

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

    SELECT strftime('%Y-%m', order_date) AS "Date", sum(amount) as "Monthly Revenue"
    FROM  orders_view join payments_view on orders_view.order_id = payments_view.order_id
    AND "status" NOT IN ('return_pending', 'returned')
    GROUP BY Date

)

select * from monthly_rev
