# AI Reporting starter boards

These dbt Charts boards query the reporting models built by this package with
`ref()`. They inherit the consuming dbt project's connection and resolve model
locations from its manifest; no company-specific database or schema is embedded.

| Board | Questions | Required model |
| --- | --- | --- |
| `spend.yml` | How is reported USD spend trending, and which models, accounts, and charge categories drive it? | `ai_reporting__cost_report` |
| `coding-activity.yml` | Who uses Claude Code and Codex CLI, and how are tokens and sessions trending? | `ai_reporting__code_report` |
| `enterprise-adoption.yml` | Which platforms and products have active enterprise users? | `ai_reporting__enterprise_report` |
| `user-adoption.yml` | Who is active this reporting month, and how does that compare with lifetime activity? | `ai_reporting__user_summary` |
| `openai-enterprise-spend.yml` | What USD estimates and credits does OpenAI compliance billing report by product, model, and user? | `openai__compliance_cost_report` (upstream OpenAI package) |
| `claude-code-interfaces.yml` | Which Claude interfaces drive sessions and reported token/cost estimates? | `claude__code_report` (upstream Claude package) |

## Open a board

1. Install this package in your dbt project and configure the upstream connections
   as described in the package README.
2. Run `dbt deps` and build the reporting model required by the board, for example
   `dbt build --select +ai_reporting__cost_report`. Models disabled by your package
   configuration must be enabled before using their boards.
3. Install [dbt Charts](https://docs.dbtcharts.com/) and run `dct init` in your
   consuming dbt project if it does not already have `dbt_charts.yml`.
4. Run `dct serve` from your consuming project. Installed package boards appear
   automatically under `/ai_reporting/<board>/`, for example
   `/ai_reporting/spend/`. To export a standalone board, use:

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

The two vendor-specific boards are optional. Build their upstream models before
opening them. OpenAI enterprise spending requires compliance billing data and
`openai__using_compliance_cost: true`. Claude interface detail requires
`claude__using_claude_code_usage_report: true` and
`claude__using_claude_code_usage_report_model_breakdown: true`; token/cost columns
are conditional on the latter. Claude USD panels assume the default
`claude__convert_cost: true` conversion to major currency units.
The combined boards remain usable with either
vendor alone. Disabled models fail explicitly rather than producing invented data.

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
- Recent Spend calendar KPIs anchor to the latest reporting day under the
  selected dimension filters, not the computer's current date. They ignore the
  analysis date range so a date selection cannot erase the comparison window.
  Latest-month spend is month-to-date through that reporting day; previous month
  is the previous full calendar month. Per-connection reporting dates are shown
  alongside comparisons because feeds with different cutoffs can make combined
  windows incomplete. The seven-day delta compares adjacent
  seven-calendar-day windows; a missing or nonpositive baseline produces no percentage.
- Spend mix and token-mix charts show the latest 36 reported months within the
  selected date range. The headline totals still cover the full selection.
- Coding tokens remain null when every token component is missing, even if the
  upstream total is zero. The non-null token-field share counts field presence,
  not source completeness: OpenAI's upstream report can zero-fill missing token
  fields, so those zeros do not prove zero real usage. Cache-read share
  uses only rows with uncached input and cache reads reported, plus cache creation
  where applicable; it measures token reuse, not dollar savings.
- User adoption is a snapshot, so its month-to-date fields follow the upstream
  reporting month and do not offer an arbitrary date filter. Active-share
  metrics exclude deleted identities and unknown activity from both numerator
  and denominator. Identities stay
  scoped to platform and source. Deleted identities remain visible for history.
- The OpenAI compliance board exposes estimated USD and credits separately,
  together with estimate coverage counts. It can overlap Codex coding cost.
  Do not sum those reports into a company bill. Missing estimates stay null.
- The Claude interface board uses upstream terminal detail discarded by the
  combined user-day model. Estimate coverage can be much smaller than activity
  coverage; compare the reported-row counts before comparing interface costs.
- User tables expose emails to everyone who can view their boards.

## Validation

After building the package's integration-test models, use the integration-test
project's profile and manifest to check and render the boards:

```sh
dct validate charts/*.yml --dbt-project-dir integration_tests --warehouse
dct render charts/*.yml --dbt-project-dir integration_tests --format png
```

Set `DBT_PROFILES_DIR` to your local profiles directory if needed. Use a date
range that includes your test data when exercising filters. The integration
seeds exercise model contracts; the previews below use
a fictional company, Pied Piper,: a year
of Claude and OpenAI connector data for about 100 people, with weekday patterns,
a staged rollout, and both vendors. They do not represent customer or Fivetran
usage, spend, or vendor list prices.

## Sample previews

- [AI Spend](previews/spend.png)
- [AI Coding Activity](previews/coding-activity.png)
- [AI Enterprise Adoption](previews/enterprise-adoption.png)
- [User adoption](previews/user-adoption.png)
- [OpenAI enterprise spending estimates](previews/openai-enterprise-spend.png)
- [Claude Code interfaces](previews/claude-code-interfaces.png)

Validated with dbt Charts `0.12.1.dev257`, dbt Core `1.12.5`, and the DuckDB
adapter `1.10.0`. No dbt model definitions were changed. Queries aggregate in
the warehouse before transferring results; daily trend caches contain summaries
rather than raw user activity. Thin daily lines show reported observations;
thick lines show seven-day averages only when all seven days have observations.

## Coverage compared with an enriched company cost board

The spend board includes month/week/day trends, model-family and charge-category
breakdowns, workspace/project and reported API-key drilldowns, and a monthly
spend matrix. Its analysis tabs share the date and dimension filters. The Recent
Spend calendar KPIs use all history under the dimension filters and explicitly
show their reporting-day anchor. Weekly periods start Monday. Token economics
shows realized unit cost on matched cost/quantity rows, not list prices or
hypothetical model-switch savings.

The underlying data is not a complete company AI bill:

| Capability | Reusable package coverage |
| --- | --- |
| Claude and OpenAI platform/API cost | Cost report; both platforms in USD |
| Model-family, model, account, and charge-category filters | Included in the spend board |
| API-key attribution | Claude only; unavailable for OpenAI in the combined cost report |
| Enterprise user cost | Claude in the combined enterprise board; OpenAI compliance USD estimates and credits on a separate optional board |
| Coding costs | Separate estimates and credits with coverage counts |
| Google/Gemini and Cursor | Not included in this package |
| Departments, teams, cost centers, employee or API-key owners | Requires an organization's own directory and attribution models |
| Finance approval, COGS tags, and budgets | Requires additional business sources and models |

Organization enrichment belongs in modeled joins, not guessed labels or chart
logic. To extend the boards with that data, build an enriched model in your own
dbt project and customize the project-local board copy to query it. Reconcile
billing scope before combining reports into a company-wide total.

Per-turn context, session, branch/task, hourly,
pricing-counterfactual, and Cursor views need event-level logs, price reference
seeds, task mappings, or additional feeds. Daily vendor reporting cannot
reconstruct session/turn history, and this pack does not infer it.
