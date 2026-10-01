{% set claude_enabled = ai_reporting_claude_user_summary_enabled() %}
{% set openai_enabled = ai_reporting_openai_user_summary_enabled() %}
{% set enabled_ctes = [] %}
{% if claude_enabled %}{% do enabled_ctes.append('claude') %}{% endif %}
{% if openai_enabled %}{% do enabled_ctes.append('openai') %}{% endif %}

{{ config(enabled=claude_enabled or openai_enabled) }}

-- One row per platform, source_relation, and user. Scoped to the fields both platforms share
-- (identity, tokens, active days, cost where available); claude's product-specific activity
-- breakdown (chat/cowork/design/office) is not carried here -- query claude__user_summary
-- directly for that detail. See DECISIONLOG.md.

with

{% if claude_enabled %}
claude as (

    select
        source_relation,
        'claude' as platform,
        user_id,
        email,
        name,
        is_user_deleted,
        {% if var('claude__using_users', True) %}role{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as role,
        {% if var('claude__using_workspace_member', True) %}count_workspaces{% else %}cast(null as {{ dbt.type_int() }}){% endif %} as count_account_scopes,
        {% if var('claude__using_workspace_member', True) and var('claude__using_workspace', True) %}workspace_names{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as account_scope_names,
        lifetime_tokens,
        month_to_date_tokens,
        lifetime_claude_cost as lifetime_cost,
        month_to_date_claude_cost as month_to_date_cost,
        lifetime_claude_list_cost as lifetime_list_cost,
        month_to_date_claude_list_cost as month_to_date_list_cost,
        lifetime_claude_discount as lifetime_discount,
        lifetime_billed_days,
        month_to_date_billed_days,
        first_billed_date,
        last_billed_date,
        {% if var('claude__using_enterprise_user_activity', True) %}
        lifetime_active_days,
        month_to_date_active_days,
        first_active_date,
        last_active_date
        {% else %}
        cast(null as {{ dbt.type_int() }}) as lifetime_active_days,
        cast(null as {{ dbt.type_int() }}) as month_to_date_active_days,
        cast(null as date) as first_active_date,
        cast(null as date) as last_active_date
        {% endif %}
    from {{ ref('claude__user_summary') }}

),
{% endif %}

{% if openai_enabled %}
openai as (

    select
        source_relation,
        'openai' as platform,
        actor_user_id as user_id,
        email,
        name,
        is_user_deleted,
        role,
        project_count as count_account_scopes,
        {% if var('openai__using_project', True) %}project_names{% else %}cast(null as {{ dbt.type_string() }}){% endif %} as account_scope_names,
        {% set openai_usage_enabled = openai.openai_enabled_usage_products() | length > 0 %}
        {% if openai_usage_enabled %}lifetime_tokens{% else %}cast(null as {{ dbt.type_int() }}){% endif %} as lifetime_tokens,
        {% if openai_usage_enabled %}month_to_date_tokens{% else %}cast(null as {{ dbt.type_int() }}){% endif %} as month_to_date_tokens,
        cast(null as {{ dbt.type_float() }}) as lifetime_cost,
        cast(null as {{ dbt.type_float() }}) as month_to_date_cost,
        cast(null as {{ dbt.type_float() }}) as lifetime_list_cost,
        cast(null as {{ dbt.type_float() }}) as month_to_date_list_cost,
        cast(null as {{ dbt.type_float() }}) as lifetime_discount,
        cast(null as {{ dbt.type_int() }}) as lifetime_billed_days,
        cast(null as {{ dbt.type_int() }}) as month_to_date_billed_days,
        cast(null as date) as first_billed_date,
        cast(null as date) as last_billed_date,
        {% if openai_usage_enabled %}
        lifetime_active_days,
        month_to_date_active_days,
        first_active_date,
        last_active_date
        {% else %}
        cast(null as {{ dbt.type_int() }}) as lifetime_active_days,
        cast(null as {{ dbt.type_int() }}) as month_to_date_active_days,
        cast(null as date) as first_active_date,
        cast(null as date) as last_active_date
        {% endif %}
    from {{ ref('openai__user_summary') }}

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
