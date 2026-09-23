-- One row per platform, source_relation, date_day, and user. estimated_cost is USD on claude
-- rows always; on openai rows it's populated only when the openai_credit_rate var is set
-- (converting Codex credits to an estimated USD figure), otherwise null. credits is OpenAI's own
-- credit unit with no published USD conversion -- always null on claude rows.

with code_report as (

    select *
    from {{ ref('int_ai_reporting__code_report') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'date_day', 'user_id', 'user_email']) }} as ai_reporting_code_report_id,
        platform,
        source_relation,
        date_day,
        user_id,
        user_email,
        count_lines_of_code_added,
        count_lines_of_code_removed,
        count_models_used,
        tokens_input,
        tokens_output,
        tokens_cache_read,
        total_tokens,
        estimated_cost,
        estimated_cost_currency,
        credits
    from code_report
)

select *
from final
