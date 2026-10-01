# Decision Log

In creating this package, which is meant for a wide range of use cases, we had to take opinionated stances on a few different questions we came across during development. We've consolidated significant choices we made here, and will continue to update as the package evolves.

## Credits vs. USD in `ai_reporting__code_report`

Claude Code reports its own usage cost in USD, while Codex CLI (OpenAI) reports usage in OpenAI credits, a unit OpenAI does not publish a dollars-per-credit conversion rate for. Because there is no package-provided way to convert credits into USD, we do not combine these two figures automatically.

`ai_reporting__code_report` keeps `credits` (OpenAI's credit unit, populated only on OpenAI rows) as its own column. `estimated_cost` is always populated in USD on Claude rows; on OpenAI rows it stays null unless you set the `openai__code_report_credit_rate` var to your own credits-to-dollars rate, in which case it's `credits * openai__code_report_credit_rate`. Since that rate is customer-supplied rather than something OpenAI publishes, treat any resulting OpenAI `estimated_cost` as an approximation, not a billed figure.

## Missing cost column on OpenAI's enterprise usage and user summary reports

The upstream `dbt_openai` end models that feed `ai_reporting__enterprise_report` and `ai_reporting__user_summary`, namely `openai__enterprise_user_report` and `openai__user_summary`, do not include a cost column today. Rather than build a new cost-allocation model to backfill a cost figure OpenAI does not expose at this grain, we leave `cost` (and the related lifetime/month-to-date cost columns in `ai_reporting__user_summary`) null on OpenAI rows. Claude rows continue to report cost in USD as normal.

If OpenAI adds a cost field to these reports in the future, we'll revisit this decision.

## Rolling up Claude Code's grain to match Codex CLI in `ai_reporting__code_report`

`claude__code_report`'s native grain is one row per `claude_code_usage_report_id`, which can vary by `terminal_type` for the same actor and day. Codex CLI's usage report from `dbt_openai` has a coarser grain of one row per day and user, with no terminal-type breakdown. To combine the two platforms into a single report, `int_ai_reporting__code_report` rolls Claude's rows up to `(source_relation, date_day, user)` to match.

One side effect of this rollup: `count_models_used` becomes an approximate sum across terminal types rather than a true distinct count of models once rolled up to the combined grain. If you need an exact distinct-model count for Claude Code usage, query `claude__code_report` directly instead of `ai_reporting__code_report`.