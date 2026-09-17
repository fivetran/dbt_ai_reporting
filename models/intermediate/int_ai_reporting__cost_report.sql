-- One row per platform, source_relation, date_day, account (workspace/project), model, cost_type
-- and token_unit_type. openai's cost endpoint reports one figure per (day, project, model,
-- cost_type) with no token-type split, so its 'tokens' cost is allocated across token_unit_type
-- by each type's share of that slice's total tokens -- the same technique
-- claude__platform_cost_usage_report already uses to split workspace cost across api_keys. A
-- 'tokens' cost row with no matching token breakdown keeps its full amount at
-- token_unit_type = null, attribution_method = 'unallocated', so no cost is ever silently
-- dropped.

{% set openai_token_columns = [
    ('input_tokens', 'input'),
    ('cache_read_tokens', 'cache_read'),
    ('output_tokens', 'output')
] %}

with claude as (

    -- claude's platform cost report already splits cost per token_unit_type, so cost and
    -- unit_quantity live on the same row here.
    select
        source_relation,
        date_day,
        'claude' as platform,
        workspace_id as account_id,
        workspace_name as account_name,
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

openai_cost as (

    select
        source_relation,
        date_day,
        project_id,
        project_name,
        model,
        model_family,
        model_variant,
        cost_type,
        openai_cost,
        currency,
        cost_attribution_method
    from {{ ref('openai__cost_usage_report') }}

),

openai_tokens_unpivoted as (

    {% for column_name, token_unit_type in openai_token_columns %}
    select
        source_relation,
        date_day,
        project_id,
        model,
        '{{ token_unit_type }}' as token_unit_type,
        {{ column_name }} as unit_quantity
    from {{ ref('openai__cost_usage_report') }}
    where {{ column_name }} > 0
    {{ 'union all' if not loop.last }}
    {% endfor %}

),

-- each token type's share of the slice's total tokens
openai_token_share as (

    select
        *,
        unit_quantity / nullif(sum(unit_quantity) over (
            partition by source_relation, date_day, project_id, model
        ), 0) as token_share
    from openai_tokens_unpivoted

),

-- 'tokens' cost allocated onto each token_unit_type by that slice's token share
openai_allocated as (

    select
        openai_cost.source_relation,
        openai_cost.date_day,
        'openai' as platform,
        openai_cost.project_id as account_id,
        openai_cost.project_name as account_name,
        cast(null as {{ dbt.type_string() }}) as api_key_id,
        cast(null as {{ dbt.type_string() }}) as api_key_name,
        openai_cost.model,
        openai_cost.model_family,
        openai_cost.model_variant,
        openai_cost.cost_type,
        openai_token_share.token_unit_type,
        openai_token_share.unit_quantity,
        openai_cost.openai_cost * openai_token_share.token_share as cost,
        openai_cost.currency,
        openai_cost.cost_attribution_method as attribution_method
    from openai_cost
    join openai_token_share
        on openai_cost.source_relation = openai_token_share.source_relation
        and openai_cost.date_day = openai_token_share.date_day
        and openai_cost.project_id = openai_token_share.project_id
        and openai_cost.model = openai_token_share.model

    where openai_cost.cost_type = 'tokens'

),

-- 'tokens' cost with no matching token breakdown -- kept whole so it is never dropped
openai_unallocated as (

    select
        openai_cost.source_relation,
        openai_cost.date_day,
        'openai' as platform,
        openai_cost.project_id as account_id,
        openai_cost.project_name as account_name,
        cast(null as {{ dbt.type_string() }}) as api_key_id,
        cast(null as {{ dbt.type_string() }}) as api_key_name,
        openai_cost.model,
        openai_cost.model_family,
        openai_cost.model_variant,
        openai_cost.cost_type,
        cast(null as {{ dbt.type_string() }}) as token_unit_type,
        cast(null as {{ dbt.type_int() }}) as unit_quantity,
        openai_cost.openai_cost as cost,
        openai_cost.currency,
        'unallocated' as attribution_method
    from openai_cost
    left join openai_token_share
        on openai_cost.source_relation = openai_token_share.source_relation
        and openai_cost.date_day = openai_token_share.date_day
        and openai_cost.project_id = openai_token_share.project_id
        and openai_cost.model = openai_token_share.model

    where openai_cost.cost_type = 'tokens'
    and openai_token_share.token_unit_type is null

),

-- non-token cost (e.g. 'other') carries no token_unit_type dimension at all
openai_other as (

    select
        source_relation,
        date_day,
        'openai' as platform,
        project_id as account_id,
        project_name as account_name,
        cast(null as {{ dbt.type_string() }}) as api_key_id,
        cast(null as {{ dbt.type_string() }}) as api_key_name,
        model,
        model_family,
        model_variant,
        cost_type,
        cast(null as {{ dbt.type_string() }}) as token_unit_type,
        cast(null as {{ dbt.type_int() }}) as unit_quantity,
        openai_cost as cost,
        currency,
        cost_attribution_method as attribution_method
    from openai_cost

    where cost_type != 'tokens'

),

openai as (

    select * from openai_allocated
    union all
    select * from openai_unallocated
    union all
    select * from openai_other

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
