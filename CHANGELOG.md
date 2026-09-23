# dbt_ai_reporting v0.1.0

This is the initial release of the `ai_reporting` dbt package.

## Initial Release

This package combines data modeled by two existing Fivetran dbt packages, `dbt_claude` (for the [Claude/Anthropic connector](link TBD)) and `dbt_openai` (for the [OpenAI connector](link TBD)), into a single set of cross-vendor reporting models. It produces the following analytics-ready tables:

- `ai_reporting__cost_report`: One row per platform, source_relation, date_day, account (workspace for Claude, project for OpenAI), model, cost_type, and token_unit_type. Combines Claude and OpenAI cost and token usage; cost is real USD on both platforms.
- `ai_reporting__code_report`: One row per platform, source_relation, date_day, and user. Combines Claude Code and Codex CLI lines-of-code and token usage. Claude cost is always in USD; OpenAI's `estimated_cost` is null unless you set `openai_credit_rate` to convert its credits into an estimated USD figure, and OpenAI credits are always available in their own column.
- `ai_reporting__enterprise_report`: One row per platform, source_relation, date_day, actor, model, and product. Combines Claude and OpenAI enterprise (seat-level) usage; cost is populated only on Claude rows.
- `ai_reporting__user_summary`: One row per platform, source_relation, and user. Combines lifetime and month-to-date usage summaries (tokens and active days on both platforms; cost on Claude only).
