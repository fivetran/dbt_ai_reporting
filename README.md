<!--section="ai_reporting_transformation_model"-->
# AI Reporting dbt Package

This dbt package combines data from Fivetran's Claude and OpenAI dbt packages into unified, cross-vendor AI usage and cost reporting models.

## Resources

- Number of materialized models¹: 4
- Connector documentation
  - [Claude/Anthropic](link TBD)
  - [OpenAI](link TBD)
- dbt package documentation
  - [GitHub repository](link TBD)
  - [dbt Docs](link TBD)
  - [Changelog](https://github.com/fivetran/dbt_ai_reporting/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package combines data modeled by two existing Fivetran dbt packages, `dbt_claude` and `dbt_openai`, and creates unified reporting models for AI cost, coding-assistant activity, enterprise (seat-level) usage, and per-user summaries across both vendors.

Currently supports the following Fivetran connectors:
- Claude/Anthropic, via [dbt_claude](https://github.com/fivetran/dbt_claude)
- OpenAI, via [dbt_openai](https://github.com/fivetran/dbt_openai)

> NOTE: This package expects both `dbt_claude` and `dbt_openai` to be installed together. There is no variable to enable only one platform. If you only use one of Claude or OpenAI, install that connector's package directly instead of this one.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<target_schema>_ai_reporting
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [`ai_reporting__cost_report`](link TBD) | One row per platform, source_relation, date_day, account (workspace for Claude, project for OpenAI), model, cost_type, and token_unit_type. Combines Claude and OpenAI cost and token usage; cost is real USD on both platforms.<br><br>**Example Analytics Questions:**<ul><li>How does token cost compare between Claude and OpenAI for the same time period?</li><li>Which models or workspaces are driving the most spend?</li><li>How is spend trending week over week across both vendors?</li></ul> |
| [`ai_reporting__code_report`](link TBD) | One row per platform, source_relation, date_day, and user. Combines Claude Code and Codex CLI lines-of-code and token usage. Claude cost is always in USD; OpenAI's `estimated_cost` is null unless you set `openai_credit_rate` to convert its credits into an estimated USD figure, and OpenAI credits are always available in their own column.<br><br>**Example Analytics Questions:**<ul><li>Which developers are the heaviest users of AI coding assistants?</li><li>How does coding-assistant activity trend over time per user?</li><li>How much token volume is Claude Code driving compared to Codex CLI?</li></ul> |
| [`ai_reporting__enterprise_report`](link TBD) | One row per platform, source_relation, date_day, actor, model, and product. Combines Claude and OpenAI enterprise (seat-level) usage; cost is populated only on Claude rows.<br><br>**Example Analytics Questions:**<ul><li>Which products (chat, Claude Code, etc.) are seeing the most usage per actor?</li><li>How does seat-level usage vary across models?</li><li>Which actors are the heaviest enterprise users on each platform?</li></ul> |
| [`ai_reporting__user_summary`](link TBD) | One row per platform, source_relation, and user. Combines lifetime and month-to-date usage summaries; tokens and active days are populated on both platforms, cost only on Claude.<br><br>**Example Analytics Questions:**<ul><li>Who are your most active users across both AI platforms?</li><li>How does a user's month-to-date usage compare to their lifetime usage?</li><li>How many active days has each user logged this month?</li></ul> |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

## Prerequisites
To use this dbt package, you must have the following:

- A Fivetran Claude/Anthropic connection **and** a Fivetran OpenAI connection both syncing data into your destination. This package is built to combine both platforms and does not support enabling only one.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, **Databricks**, or **DuckDB** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement).
- To add the package to your dbt project, follow the setup instructions below.

### Installing the Package
Include the following github package version in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/ai_reporting
    version: [">=0.1.0", "<0.2.0"] # we recommend using ranges to capture non-breaking changes automatically
```

Do NOT include `dbt_claude` or `dbt_openai` directly in this file. This package depends on both and will install them for you.

#### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

### Define database and schema variables
This package does not have its own database or schema variable — its output schema is hardcoded to `<target_schema>_ai_reporting` in `dbt_project.yml` and cannot be renamed. The database and schema variables you need to set are the ones for the two upstream packages this one combines.

#### Option A: Single connection(s)
By default, `dbt_claude` and `dbt_openai` look for their respective data in your target database. If this is not where your Claude or OpenAI data is stored, add the relevant `<connector>_database` and `<connector>_schema` variables to your `dbt_project.yml` file (see below).
> Please note, cross-database querying, where the `*_database` variable differs from the database specified in your `profiles.yml`, is not supported by all dbt adapters (e.g., dbt-redshift). Refer to the documentation for your specific destination adapter for more details on its capabilities.

```yml
vars:
    claude_schema: claude
    claude_database: your_database_name

    openai_schema: openai
    openai_database: your_database_name
```

#### Option B: Union multiple connections
If you have multiple Claude or OpenAI connections of the same type in Fivetran and would like to use this package on all of them simultaneously, `dbt_claude` and `dbt_openai` each support unioning their own sources. For each source table, the respective upstream package will union all of the data together and pass the unioned table into its transformations, and this package's `source_relation` column continues through to indicate the origin of each record.

To use this functionality, set the below variables in your root `dbt_project.yml` file, following each upstream package's own documentation for the exact structure:
```yml
# dbt_project.yml

vars:
  claude_sources:
    - database: connection_1_destination_name # Required
      schema: connection_1_schema_name # Required
      name: connection_1_source_name

    - database: connection_2_destination_name
      schema: connection_2_schema_name
      name: connection_2_source_name

  openai_sources:
    - database: connection_1_destination_name # Required
      schema: connection_1_schema_name # Required
      name: connection_1_source_name

    - database: connection_2_destination_name
      schema: connection_2_schema_name
      name: connection_2_source_name
```

##### Optional: Incorporate unioned sources into DAG
If you use [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore) and are unioning multiple Claude or OpenAI connections, you can define your sources in a property `.yml` file. Set the variable `has_defined_sources: true` in your `dbt_project.yml`. Otherwise, your connections won't appear in your DAG. See the `union_connections` macro [documentation](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#optional-union-connections-defined-sources-configuration) for full configuration details.

##### Optional: Estimate OpenAI Codex cost in USD
`ai_reporting__code_report` leaves `estimated_cost` null on OpenAI rows by default, since OpenAI's Codex credits have no published USD conversion rate. If you want an approximate USD figure anyway, set your own credits-to-dollars rate:
```yml
# dbt_project.yml

vars:
  openai_credit_rate: 0.04 # your own credits-to-USD rate; estimated_cost = credits * openai_credit_rate
```
This is a customer-supplied estimate, not a value OpenAI publishes -- see [DECISIONLOG.md](https://github.com/fivetran/dbt_ai_reporting/blob/main/DECISIONLOG.md) for context.

## Opinionated modeling decisions
Building a package that combines two independently designed source packages required a few opinionated calls, for example how we handle Claude's USD cost alongside OpenAI's non-USD credit unit, and how we roll up Claude Code's grain to match Codex CLI's. We've documented these choices in [DECISIONLOG.md](https://github.com/fivetran/dbt_ai_reporting/blob/main/DECISIONLOG.md) and welcome feedback on them.

<!--section-end-->
<!--section="ai_reporting_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the latest version of the package. We highly recommend you stay consistent with the latest version and refer to the [CHANGELOG](https://github.com/fivetran/dbt_ai_reporting/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

#### Contributors
We thank everyone who has taken the time to contribute. Each PR, bug report, and feature request has made this package better and is truly appreciated.

<!--section-end-->

## Are there any resources available?
- If you encounter any questions or want to reach out for help, see the [GitHub Issue](link TBD) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran, or would like to request a future dbt package to be developed, then feel free to fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
