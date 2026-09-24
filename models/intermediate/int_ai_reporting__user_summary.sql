-- One row per platform, source_relation, and user. Scoped to the fields both platforms share
-- (identity, tokens, active days, cost where available); claude's product-specific activity
-- breakdown (chat/cowork/design/office) is not carried here -- query claude__user_summary
-- directly for that detail. See DECISIONLOG.md.

with claude as (

    select
        source_relation,
        'claude' as platform,
        user_id,
        email,
        name,
        is_user_deleted,
        role,
        count_workspaces as count_account_scopes,
        workspace_names as account_scope_names,
        {# is_workspace_admin,
        is_workspace_developer, #}
        {# cast(null as {{ dbt.type_int() }}) as project_role_count,
        cast(null as {{ dbt.type_string() }}) as project_role_names, #}
        lifetime_tokens,
        month_to_date_tokens,
        {# cast(null as {{ dbt.type_int() }}) as lifetime_num_model_requests,
        cast(null as {{ dbt.type_int() }}) as month_to_date_num_model_requests, #}
        lifetime_claude_cost,
        month_to_date_claude_cost,
        lifetime_claude_list_cost,
        month_to_date_claude_list_cost,
        lifetime_claude_discount,
        lifetime_billed_days,
        month_to_date_billed_days,
        first_billed_date,
        last_billed_date,
        lifetime_active_days,
        month_to_date_active_days,
        first_active_date,
        last_active_date
    from {{ ref('claude__user_summary') }}

),

openai as (

    select
        source_relation,
        'openai' as platform,
        actor_user_id as user_id,
        email,
        name,
        cast(null as {{ dbt.type_boolean() }}) as is_user_deleted, -- asking catherine to add this in 
        role,
        project_count as count_account_scopes,
        project_names as account_scope_names,
        {# cast(null as {{ dbt.type_boolean() }}) as is_workspace_admin,
        cast(null as {{ dbt.type_boolean() }}) as is_workspace_developer, #}
        {# project_role_count,
        project_role_names, #}
        lifetime_tokens,
        month_to_date_tokens,
        {# lifetime_num_model_requests,
        month_to_date_num_model_requests, #}
        
        -- may bring these back in if we can get them from the compliance tables
        cast(null as {{ dbt.type_float() }}) as lifetime_claude_cost,
        cast(null as {{ dbt.type_float() }}) as month_to_date_claude_cost,
        cast(null as {{ dbt.type_float() }}) as lifetime_claude_list_cost,
        cast(null as {{ dbt.type_float() }}) as month_to_date_claude_list_cost,
        cast(null as {{ dbt.type_float() }}) as lifetime_claude_discount,
        cast(null as {{ dbt.type_int() }}) as lifetime_billed_days,
        cast(null as {{ dbt.type_int() }}) as month_to_date_billed_days,
        cast(null as date) as first_billed_date,
        cast(null as date) as last_billed_date,
        lifetime_active_days,
        month_to_date_active_days,
        first_active_date,
        last_active_date
    from {{ ref('openai__user_summary') }}

),

unioned as (

    select * from claude
    union all
    select * from openai

)

select *
from unioned
