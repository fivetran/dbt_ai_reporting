{% set claude_enabled = ai_reporting_claude_code_enabled() %}
{% set openai_enabled = ai_reporting_openai_code_enabled() %}
{% set enabled_ctes = [] %}
{% if claude_enabled %}{% do enabled_ctes.append('claude') %}{% endif %}
{% if openai_enabled %}{% do enabled_ctes.append('openai') %}{% endif %}

{{ config(enabled=claude_enabled or openai_enabled) }}

-- One row per platform, source_relation, date_day, and user. Claude's native grain (one row per
-- claude_code_usage_report_id, which can vary by terminal_type for the same actor/day) is rolled
-- up to match Codex's (day, user) grain here; count_models_used becomes an approximate sum across
-- terminal types rather than a true distinct count once rolled up -- see DECISIONLOG.md.

with

{% if claude_enabled %}
claude as (

    select
        source_relation,
        report_date as date_day,
        'claude' as platform,
        {% if var('claude__using_users', True) %}
        user_id,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as user_id,
        {% endif %}
        actor_email as user_email,
        sum(count_sessions) as count_sessions,
        sum(count_lines_of_code_added) as count_lines_of_code_added,
        sum(count_lines_of_code_removed) as count_lines_of_code_removed,

        {% if var('claude__using_claude_code_usage_report_model_breakdown', True) %}
        sum(count_models_used) as count_models_used,
        sum(tokens_input) as tokens_input,
        sum(tokens_output) as tokens_output,
        sum(tokens_cache_read) as tokens_cache_read,
        sum(tokens_cache_creation) as tokens_cache_creation,
        sum(total_tokens) as total_tokens,
        sum(estimated_cost) as estimated_cost,
        max(estimated_cost_currency) as estimated_cost_currency,
        {% else %}
        cast(null as {{ dbt.type_integer() }}) as count_models_used,
        cast(null as {{ dbt.type_integer() }}) as tokens_input,
        cast(null as {{ dbt.type_integer() }}) as tokens_output,
        cast(null as {{ dbt.type_integer() }}) as tokens_cache_read,
        cast(null as {{ dbt.type_integer() }}) as tokens_cache_creation,
        cast(null as {{ dbt.type_integer() }}) as total_tokens,
        cast(null as {{ dbt.type_float() }}) as estimated_cost,
        cast(null as {{ dbt.type_string() }}) as estimated_cost_currency,
        {% endif %}
        cast(null as {{ dbt.type_float() }}) as credits

    from {{ ref('claude__code_report') }}
    {{ dbt_utils.group_by(n=5) }}

),
{% endif %}

{% if openai_enabled %}
openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        user_id,
        {% if var('openai__using_codex_usage', True) %}
        actor_email as user_email,
        count_threads as count_sessions,
        count_lines_of_code_added,
        count_lines_of_code_removed,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as user_email,
        cast(null as {{ dbt.type_integer() }}) as count_sessions,
        cast(null as {{ dbt.type_integer() }}) as count_lines_of_code_added,
        cast(null as {{ dbt.type_integer() }}) as count_lines_of_code_removed,
        {% endif %}

        {% if var('openai__using_codex_usage_model', True) %}
        count_models_used,
        {% else %}
        cast(null as {{ dbt.type_integer() }}) as count_models_used,
        {% endif %}
        
        input_tokens as tokens_input,
        output_tokens as tokens_output,
        cache_read_tokens as tokens_cache_read,
        cast(null as {{ dbt.type_integer() }}) as tokens_cache_creation,
        coalesce(input_tokens, 0) + coalesce(output_tokens, 0) + coalesce(cache_read_tokens, 0) as total_tokens,
        {% if var('openai__code_report_credit_rate', []) != [] %}
            estimated_cost_amount as estimated_cost,
        {% else %}
            cast(null as {{ dbt.type_float() }}) as estimated_cost,
        {% endif %}
        cast(null as {{ dbt.type_string() }}) as estimated_cost_currency,
        credits
    from {{ ref('openai__code_report') }}

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
