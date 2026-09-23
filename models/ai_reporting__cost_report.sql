-- One row per platform, source_relation, date_day, account, model, cost_type, and
-- token_unit_type. Cost is real USD on both platforms and is safe to sum across platforms.

with cost_report as (

    select *
    from {{ ref('int_ai_reporting__cost_report') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'date_day', 'account_id', 'model', 'cost_type', 'token_unit_type']) }} as ai_reporting_cost_report_id,
        platform,
        source_relation,
        date_day,
        account_id,
        account_name,
        model,
        model_family,
        model_variant,
        cost_type,
        token_unit_type,
        unit_quantity,
        cost,
        currency,
        attribution_method
    from cost_report
)

select *
from final
