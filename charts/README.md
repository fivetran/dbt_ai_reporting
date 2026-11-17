# AI Reporting starter boards

These dbt Charts boards query the reporting models built by this package with
`ref()`. They inherit the consuming dbt project's connection and resolve model
locations from its manifest; no company-specific database or schema is embedded.

| Board | Questions | Required model |
| --- | --- | --- |
| `spend.yml` | How is reported USD spend trending, and which models, accounts, and charge categories drive it? | `ai_reporting__cost_report` |
| `coding-activity.yml` | Who uses Claude Code and Codex CLI, and how are tokens and sessions trending? | `ai_reporting__code_report` |
| `enterprise-adoption.yml` | Which platforms and products have active enterprise users? | `ai_reporting__enterprise_report` |

## Open a board

1. Install this package in your dbt project and configure the upstream connections
   as described in the package README.
2. Run `dbt deps` and build the reporting model required by the board, for example
   `dbt build --select +ai_reporting__cost_report`. Models disabled by your package
   configuration must be enabled before using their boards.
3. Install [dbt Charts](https://docs.dbtcharts.com/) and run `dct init` in your
   consuming dbt project if it does not already have `dbt_charts.yml`.
4. From that project, render a board:

   ```sh
   dct render dbt_packages/ai_reporting/charts/spend.yml --format html
   ```

To customize a board, copy it into `charts/ai_reporting/` in your project.
The project's copy replaces the package board of the same name.
The boards offer a date range and platform filter. Unset filters include all
available history and platforms; they work with one platform enabled as well as
both. A platform absent from a report does not appear in its filter.

## Reading the numbers

- Spend comes exclusively from `ai_reporting__cost_report`, whose cost is actual
  USD on both platforms. Do not add the other reports' costs to it: the reports
  are different views of activity, not disjoint billing ledgers.
- Coding estimates remain separate from Codex credits. OpenAI estimates require
  `openai__code_report_credit_rate`; Claude estimates require model breakdown
  data. The user table includes the number of reported days with an estimate so
  partial coverage is visible. A missing estimate remains null.
- Sessions mean Claude sessions or Codex threads. Lines of code and token counts
  measure activity, not productivity or business value.
- Active users have positive reported usage. User identities stay scoped to
  platform and source connection; the boards do not deduplicate people across
  vendors or connections. Product counts can overlap.
- Enterprise quantities stay separated by vendor unit, product, and model.
  OpenAI enterprise costs are unavailable; this board does not compare them.
- Cursor is not supported by this package.

## Validation

After building the package's integration-test models, use the integration-test
project's profile and manifest to check and render the boards:

```sh
dct validate charts/*.yml --dbt-project-dir integration_tests --warehouse
dct render charts/*.yml --dbt-project-dir integration_tests --format png
```

Set `DBT_PROFILES_DIR` to your local profiles directory if needed. Use a date
range that includes your test data when exercising filters. Screenshots made
from integration-test seeds are sample data, not customer or Fivetran spend.

## Sample previews

These previews use only the package's integration-test seeds:

- [AI Spend](previews/spend.png)
- [AI Coding Activity](previews/coding-activity.png)
- [AI Enterprise Adoption](previews/enterprise-adoption.png)

Validated with dbt Charts `0.11.1.dev1374`, dbt Core `1.12.5`, and the DuckDB
adapter `1.10.0`. No dbt model or Quickstart configuration changes are required.
