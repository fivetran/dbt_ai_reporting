{% set claude_enabled = ai_reporting_claude_enterprise_enabled() %}
{% set openai_enabled = ai_reporting_openai_enterprise_enabled() %}
{% set enabled_ctes = [] %}
{% if claude_enabled %}{% do enabled_ctes.append('claude') %}{% endif %}
{% if openai_enabled %}{% do enabled_ctes.append('openai') %}{% endif %}

{{ config(enabled=claude_enabled or openai_enabled) }}

-- One row per platform, source_relation, date_day, actor, model, and product

with

{% if claude_enabled %}
claude as (

    select
        source_relation,
        date_day,
        'claude' as platform,
        actor_user_id,
        {% if var('claude__using_enterprise_user_actor', True) %}actor_email{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as actor_email,
        {% if var('claude__using_enterprise_user_actor', True) %}actor_name{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as actor_name,
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
{% endif %}

{% if openai_enabled %}
openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
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
{% endif %}

unioned as (

    {% for cte in enabled_ctes %}
    select * from {{ cte }}
    {% if not loop.last %} union all {% endif %}
    {% endfor %}

)

select *
from unioned
