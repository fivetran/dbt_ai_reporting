-- One row per platform, source_relation, date_day, account, api_key (claude only), model,
-- cost_type, and token_unit_type. Cost is real USD on both platforms and is safe to sum across
-- platforms. On openai rows with cost_type = 'tokens', cost is allocated across token_unit_type
-- by each type's token share; a 'tokens' cost with no matching token breakdown keeps its full
-- amount at token_unit_type = null and attribution_method = 'unallocated' (see
-- int_ai_reporting__cost_report for the allocation logic).

with cost_report as (

    select *
    from {{ ref('int_ai_reporting__cost_report') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'date_day', 'account_id', 'api_key_id', 'model', 'cost_type', 'token_unit_type']) }} as ai_reporting_cost_report_id,
        platform,
        source_relation,
        date_day,
        account_id,
        account_name,
        api_key_id,
        api_key_name,
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
