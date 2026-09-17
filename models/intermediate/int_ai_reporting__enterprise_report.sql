-- One row per platform, source_relation, date_day, actor, model, and product. Cost is populated
-- only on claude rows -- openai's enterprise usage report carries no cost column today (see
-- DECISIONLOG.md).

with claude as (

    select
        source_relation,
        date_day,
        'claude' as platform,
        organization_id,
        organization_name,
        cast(null as {{ dbt.type_string() }}) as project_id,
        cast(null as {{ dbt.type_string() }}) as project_name,
        actor_user_id,
        actor_email,
        actor_name,
        product,
        model,
        model_family,
        model_variant,
        token_unit_type as unit_type,
        unit_quantity,
        request as num_model_requests,
        claude_cost as cost,
        currency
    from {{ ref('claude__enterprise_cost_usage_report') }}

),

openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        cast(null as {{ dbt.type_string() }}) as organization_id,
        cast(null as {{ dbt.type_string() }}) as organization_name,
        project_id,
        project_name,
        actor_user_id,
        actor_email,
        cast(null as {{ dbt.type_string() }}) as actor_name,
        product,
        model,
        model_family,
        model_variant,
        quantity_unit as unit_type,
        quantity as unit_quantity,
        num_model_requests,
        cast(null as {{ dbt.type_float() }}) as cost,
        cast(null as {{ dbt.type_string() }}) as currency
    from {{ ref('openai__enterprise_user_report') }}

),

unioned as (

    select * from claude
    union all
    select * from openai

),

final as (

    select *
    from unioned

)

select *
from final
