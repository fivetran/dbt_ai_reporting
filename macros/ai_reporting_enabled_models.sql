{% macro ai_reporting_claude_cost_enabled() %}
    {{ return(var('claude__using_cost_report', True) and var('claude__using_message_usage_report', True) and var('claude__using_api_key', True)) }}
{% endmacro %}

{% macro ai_reporting_openai_cost_enabled() %}
    {{ return(var('openai__using_cost', True) or var('openai__using_completion', True)) }}
{% endmacro %}


{% macro ai_reporting_claude_enterprise_enabled() %}
    {{ return(var('claude__using_enterprise_user_cost_report', True) and var('claude__using_enterprise_user_usage_report', True)) }}
{% endmacro %}

{% macro ai_reporting_openai_enterprise_enabled() %}
    {{ return(openai.openai_enabled_usage_products() | length > 0) }}
{% endmacro %}


{% macro ai_reporting_claude_code_enabled() %}
    {{ return(var('claude__using_claude_code_usage_report', True)) }}
{% endmacro %}

{% macro ai_reporting_openai_code_enabled() %}
    {{ return(var('openai__using_codex_usage', True) or var('openai__using_codex_usage_model', True)) }}
{% endmacro %}


{% macro ai_reporting_claude_user_summary_enabled() %}
    {{ return(var('claude__using_enterprise_user_actor', True) and var('claude__using_enterprise_user_cost_report', True) and var('claude__using_enterprise_user_usage_report', True)) }}
{% endmacro %}

{% macro ai_reporting_openai_user_summary_enabled() %}
    {{ return(var('openai__using_project_user', True)) }}
{% endmacro %}