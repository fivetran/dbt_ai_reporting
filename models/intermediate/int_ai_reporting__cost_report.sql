{% set claude_enabled = ai_reporting_claude_cost_enabled() %}
{% set openai_enabled = ai_reporting_openai_cost_enabled() %}
{% set enabled_ctes = [] %}
{% if claude_enabled %}{% do enabled_ctes.append('claude') %}{% endif %}
{% if openai_enabled %}{% do enabled_ctes.append('openai') %}{% endif %}

{{ config(enabled=claude_enabled or openai_enabled) }}

-- One row per platform, source_relation, date_day, account (workspace/project), model, cost_type
-- and token_unit_type. openai__cost_usage_report already splits cost per token_unit_type, so no
-- allocation is needed here.

with

{% if claude_enabled %}
claude as (

    select
        source_relation,
        date_day,
        'claude' as platform,
        workspace_id as account_id,
        {% if var('claude__using_workspace', True) %}workspace_name{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as account_name,
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
{% endif %}

{% if openai_enabled %}
openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        project_id as account_id,
        {% if var('openai__using_project', True) %}project_name{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as account_name,
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
{% endif %}

unioned as (

    {% for cte in enabled_ctes %}
    select * from {{ cte }}
    {% if not loop.last %} union all {% endif %}
    {% endfor %}

)

select *
from unioned
