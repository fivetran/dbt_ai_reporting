-- One row per platform, source_relation, date_day, and user. Cost is not comparable across
-- platforms here: claude_estimated_cost is USD, openai_credits is OpenAI's own credit unit with
-- no published USD conversion -- they are kept as separate columns rather than combined.

with code_report as (

    select *
    from {{ ref('int_ai_reporting__code_report') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'date_day', 'user_id', 'actor_email']) }} as ai_reporting_code_report_id,
        platform,
        source_relation,
        date_day,
        user_id,
        actor_email,
        count_sessions,
        count_commits,
        count_pull_requests,
        count_lines_of_code_added,
        count_lines_of_code_removed,
        count_threads,
        count_turns,
        count_models_used,
        tokens_input,
        tokens_output,
        tokens_cache_creation,
        tokens_cache_read,
        total_tokens,
        claude_estimated_cost,
        claude_estimated_cost_currency,
        openai_credits
    from code_report
)

select *
from final
