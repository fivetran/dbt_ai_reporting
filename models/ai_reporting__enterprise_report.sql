-- One row per platform, source_relation, date_day, actor, model, and product. cost is USD and
-- populated only on claude rows -- see int_ai_reporting__enterprise_report.sql for why.

with enterprise_report as (

    select *
    from {{ ref('int_ai_reporting__enterprise_report') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'date_day', 'actor_user_id', 'model', 'product', 'unit_type']) }} as ai_reporting_enterprise_report_id,
        platform,
        source_relation,
        date_day,
        organization_id,
        organization_name,
        project_id,
        project_name,
        actor_user_id,
        actor_email,
        actor_name,
        product,
        model,
        model_family,
        model_variant,
        unit_type,
        unit_quantity,
        num_model_requests,
        cost,
        currency
    from enterprise_report
)

select *
from final
