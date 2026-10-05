{{ config(enabled=ai_reporting_claude_user_summary_enabled() or ai_reporting_openai_user_summary_enabled()) }}

-- One row per platform, source_relation, and user. Cost fields are USD and populated only on
-- claude rows -- openai's user summary carries no cost column today (see DECISIONLOG.md).

with user_summary as (

    select *
    from {{ ref('int_ai_reporting__user_summary') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['platform', 'source_relation', 'user_id']) }} as user_summary_id,
        platform,
        source_relation,
        user_id,
        email,
        name,
        is_user_deleted,
        role,
        count_account_scopes,
        account_scope_names,
        lifetime_tokens,
        month_to_date_tokens,
        lifetime_cost,
        month_to_date_cost,
        lifetime_list_cost,
        month_to_date_list_cost,
        lifetime_discount,
        lifetime_billed_days,
        month_to_date_billed_days,
        first_billed_date,
        last_billed_date,
        lifetime_active_days,
        month_to_date_active_days,
        first_active_date,
        last_active_date
    from user_summary
)

select *
from final
