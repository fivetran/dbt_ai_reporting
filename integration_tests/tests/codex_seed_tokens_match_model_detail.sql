with usage as (
    select
        cast(start_time as date) as date_day,
        user_id,
        sum(total_uncached_text_input_token) as input_tokens,
        sum(total_cached_text_input_token) as cache_read_tokens,
        sum(total_text_output_token) as output_tokens
    from {{ ref('openai_codex_usage') }}
    where not _fivetran_deleted
    group by 1, 2
),

model_detail as (
    select
        cast(codex_usage_start_time as date) as date_day,
        codex_usage_user_id as user_id,
        sum(uncached_text_input_token) as input_tokens,
        sum(cached_text_input_token) as cache_read_tokens,
        sum(text_output_token) as output_tokens
    from {{ ref('openai_codex_usage_model') }}
    where not _fivetran_deleted
    group by 1, 2
)

select usage.*
from usage
left join model_detail
    on model_detail.date_day = usage.date_day
    and model_detail.user_id = usage.user_id
where
(usage.input_tokens <> model_detail.input_tokens
        or (usage.input_tokens is null and model_detail.input_tokens is not null)
        or (usage.input_tokens is not null and model_detail.input_tokens is null))
    or (usage.cache_read_tokens <> model_detail.cache_read_tokens
        or (usage.cache_read_tokens is null and model_detail.cache_read_tokens is not null)
        or (usage.cache_read_tokens is not null and model_detail.cache_read_tokens is null))
    or (usage.output_tokens <> model_detail.output_tokens
        or (usage.output_tokens is null and model_detail.output_tokens is not null)
        or (usage.output_tokens is not null and model_detail.output_tokens is null))
