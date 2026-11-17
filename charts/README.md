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
The project's copy replaces the package board of the same name. Render a
customized copy with `dct render charts/ai_reporting/spend.yml --format html`.
The boards offer date and platform filters. The spend board also offers
month/week/day granularity, model-family/model, workspace/project, charge-type,
and reported API-key filters. The enterprise board adds product/model filters. Unset filters include all
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
  vendors or connections. Coding users are identified by user ID when present,
  otherwise by email; the table shows the latest reported email. Unidentified
  coding activity remains in volumes but is excluded from user counts and
  rankings. Product counts can overlap.
- Enterprise quantities stay separated by vendor unit, product, and model.
  The enterprise user table shows reported Claude costs; OpenAI enterprise
  costs remain blank because they are unavailable, not zero.
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
- [Account drilldown](previews/spend-accounts.png)
- [API-key drilldown](previews/spend-api-keys.png)
- [Monthly spend matrix](previews/spend-monthly.png)

Validated with dbt Charts `0.11.1.dev1374`, dbt Core `1.12.5`, and the DuckDB
adapter `1.10.0`. No dbt model or Quickstart configuration changes are required.

## Coverage compared with an enriched company cost board

The spend board includes month/week/day trends, model-family and charge-category
breakdowns, workspace/project and reported API-key drilldowns, and a monthly
spend matrix. Its date and dimension filters apply to both the Overview and
Accounts and API Keys tabs. Weekly periods start Monday.

The underlying data is not a complete company AI bill:

| Capability | Reusable package coverage |
| --- | --- |
| Claude and OpenAI platform/API cost | Cost report; both platforms in USD |
| Model-family, model, account, and charge-category filters | Included in the spend board |
| API-key attribution | Claude only; unavailable for OpenAI in the combined cost report |
| Enterprise user cost | Claude only, shown separately on the enterprise board |
| Coding costs | Separate estimates and credits with coverage counts |
| Google/Gemini and Cursor | Not included in this package |
| Departments, teams, cost centers, employee or API-key owners | Requires an organization's own directory and attribution models |
| Finance approval, COGS tags, and budgets | Requires additional business sources and models |

Organization enrichment belongs in modeled joins, not guessed labels or chart
logic. To extend the boards with that data, build an enriched model in your own
dbt project and customize the project-local board copy to query it. Reconcile
billing scope before combining reports into a company-wide total.
