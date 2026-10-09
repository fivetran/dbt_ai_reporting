# dbt_ai_reporting v0.1.0

This is the initial release of the AI Reporting dbt package!

## What does this dbt package do?

This package combines data modeled by two existing Fivetran dbt packages, [`dbt_claude`](https://github.com/fivetran/dbt_claude) (for the [Claude connector](https://fivetran.com/docs/connectors/applications/claude)) and [`dbt_openai`](https://github.com/fivetran/dbt_openai) (for the [OpenAI connector](https://fivetran.com/docs/connectors/applications/openai)), into a single set of cross-vendor AI reporting models, including:

- Creates analytics-ready end models that unify Claude and OpenAI cost, usage, and activity data into a consistent schema across both platforms.
- Generates a comprehensive data dictionary of your modeled AI reporting data through the [dbt docs site](https://fivetran.github.io/dbt_ai_reporting/).

The following table provides a detailed list of all models materialized within this package by default.

| **model** | **description** |
| --------- | --------------- |
| [ai_reporting__cost_report](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__cost_report) | One row per platform, source_relation, date_day, account (workspace for Claude, project for OpenAI), model, cost_type, and token_unit_type. Combines Claude and OpenAI cost and token usage. Cost is real USD on both platforms. |
| [ai_reporting__code_report](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__code_report) | One row per platform, source_relation, date_day, and user. Combines Claude Code and Codex CLI lines-of-code and token usage. Claude cost is always in USD when `claude__using_claude_code_usage_report_model_breakdown` is enabled; OpenAI's estimated_cost is null unless you set the `openai__code_report_credit_rate` variable. |
| [ai_reporting__enterprise_report](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__enterprise_report) | One row per platform, source_relation, date_day, actor, model, and product. Combines Claude and OpenAI enterprise (seat-level) usage. Cost is populated only on Claude rows. |
| [ai_reporting__user_summary](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__user_summary) | One row per platform, source_relation, and user. Combines lifetime and month-to-date usage summaries (tokens and active days on both platforms; cost on Claude only). |
