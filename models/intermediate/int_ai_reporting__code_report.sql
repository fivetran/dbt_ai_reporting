-- One row per platform, source_relation, date_day, and user. Claude's native grain (one row per
-- claude_code_usage_report_id, which can vary by terminal_type for the same actor/day) is rolled
-- up to match Codex's (day, user) grain here; count_models_used becomes an approximate sum across
-- terminal types rather than a true distinct count once rolled up -- see DECISIONLOG.md.

with claude_raw as (

    select *
    from {{ ref('claude__code_report') }}

),

claude as (

    select
        source_relation,
        report_date as date_day,
        'claude' as platform,
        user_id,
        actor_email_address as user_email,
        {# sum(count_sessions) as count_sessions,
        sum(count_commits) as count_commits,
        sum(count_pull_requests) as count_pull_requests, #}
        sum(count_lines_of_code_added) as count_lines_of_code_added,
        sum(count_lines_of_code_removed) as count_lines_of_code_removed,
        {# cast(null as {{ dbt.type_int() }}) as count_threads,
        cast(null as {{ dbt.type_int() }}) as count_turns, #}
        sum(count_models_used) as count_models_used,
        sum(tokens_input) as tokens_input,
        sum(tokens_output) as tokens_output,
        {# sum(tokens_cache_creation) as tokens_cache_creation, #}
        sum(tokens_cache_read) as tokens_cache_read,
        sum(total_tokens) as total_tokens,
        sum(estimated_cost) as estimated_cost,
        max(estimated_cost_currency) as estimated_cost_currency,
        cast(null as {{ dbt.type_float() }}) as credits
    from claude_raw
    {{ dbt_utils.group_by(n=5) }}

),

openai as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        user_id,
        actor_email as user_email,
        {# cast(null as {{ dbt.type_int() }}) as count_sessions,
        cast(null as {{ dbt.type_int() }}) as count_commits,
        cast(null as {{ dbt.type_int() }}) as count_pull_requests, #}
        count_lines_of_code_added,
        count_lines_of_code_removed,
        {# count_threads,
        count_turns, #}
        count_models_used,
        input_tokens as tokens_input,
        output_tokens as tokens_output,
        {# cast(null as {{ dbt.type_int() }}) as tokens_cache_creation, #}
        cache_read_tokens as tokens_cache_read,
        coalesce(input_tokens, 0) + coalesce(output_tokens, 0) + coalesce(cache_read_tokens, 0) as total_tokens,
        {% if var('openai_credit_rate', []) != [] %}
            credits * {{ var('openai_credit_rate', 1) }} as estimated_cost,
        {% else %}
            cast(null as {{ dbt.type_float() }}) as estimated_cost,
        {% endif %}
        cast(null as {{ dbt.type_string() }}) as estimated_cost_currency,
        credits
    from {{ ref('openai__code_report') }}

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
