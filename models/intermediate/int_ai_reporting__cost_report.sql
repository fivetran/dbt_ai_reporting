-- One row per platform, source_relation, date_day, account (workspace/project), model, cost_type
-- and token_unit_type. openai__cost_usage_report already splits cost per token_unit_type, so no
-- allocation is needed here.

with claude as (

    select
        source_relation,
        date_day,
        'claude' as platform,
        workspace_id as account_id,
        workspace_name as account_name,
        api_key_id,
        api_key_name,
        model,
        model_family,
        model_variant,
        cost_type,
        token_unit_type,
        unit_quantity,
        claude_cost as cost,
        currency,
        allocation_method as attribution_method
    from {{ ref('claude__platform_cost_usage_report') }}

),

openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        project_id as account_id,
        project_name as account_name,
        cast(null as {{ dbt.type_string() }}) as api_key_id,
        cast(null as {{ dbt.type_string() }}) as api_key_name,
        model,
        model_family,
        model_variant,
        cost_type,
        token_unit_type,
        token_quantity as unit_quantity,
        openai_cost as cost,
        currency,
        cost_attribution_method as attribution_method
    from {{ ref('openai__cost_usage_report') }}

),

unioned as (

    select * from claude
    union all
    select * from openai

)

select *
from unioned
