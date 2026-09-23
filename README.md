<!--section="ai_reporting_transformation_model"-->
# AI Reporting dbt Package

This dbt package combines data from Fivetran's Claude and OpenAI dbt packages into unified, cross-vendor AI usage and cost reporting models.

## Resources

- Number of materialized models¹: 4
- Connector documentation
  - [Claude](https://fivetran.com/docs/connectors/applications/claude)
  - [OpenAI](https://fivetran.com/docs/connectors/applications/openai)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_ai_reporting)
  - [dbt Docs](https://fivetran.github.io/dbt_ai_reporting/#!/overview)
  - [Changelog](https://github.com/fivetran/dbt_ai_reporting/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package creates unified reporting models for AI cost, coding-assistant activity, enterprise (seat-level) usage, and per-user summaries across different vendors.

Currently supports the following Fivetran connectors:
- [Claude](https://github.com/fivetran/dbt_claude)
- [OpenAI](https://github.com/fivetran/dbt_openai)

> The individual Claude and OpenAI tables have additional platform-specific metrics better suited for deep-dive analyses.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<target_schema>_ai_reporting
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [`ai_reporting__cost_report`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__cost_report) | One row per platform, source_relation, date_day, account (workspace for Claude, project for OpenAI), model, cost_type, and token_unit_type. Combines Claude and OpenAI cost and token usage; cost is real USD on both platforms.<br><br>**Example Analytics Questions:**<ul><li>How does token cost compare between Claude and OpenAI for the same time period?</li><li>Which models or workspaces are driving the most spend?</li><li>How is spend trending week over week across both vendors?</li></ul> |
| [`ai_reporting__code_report`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__code_report) | One row per platform, source_relation, date_day, and user. Combines Claude Code and Codex CLI lines-of-code and token usage. Claude cost is always in USD; OpenAI's `estimated_cost` is null unless you set `openai_credit_rate` to convert its credits into an estimated USD figure, and OpenAI credits are always available in their own column.<br><br>**Example Analytics Questions:**<ul><li>Which developers are the heaviest users of AI coding assistants?</li><li>How does coding-assistant activity trend over time per user?</li><li>How much token volume is Claude Code driving compared to Codex CLI?</li></ul> |
| [`ai_reporting__enterprise_report`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__enterprise_report) | One row per platform, source_relation, date_day, actor, model, and product. Combines Claude and OpenAI enterprise (seat-level) usage; cost is populated only on Claude rows.<br><br>**Example Analytics Questions:**<ul><li>Which products (chat, Claude Code, etc.) are seeing the most usage per actor?</li><li>How does seat-level usage vary across models?</li><li>Which actors are the heaviest enterprise users on each platform?</li></ul> |
| [`ai_reporting__user_summary`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__user_summary) | One row per platform, source_relation, and user. Combines lifetime and month-to-date usage summaries; tokens and active days are populated on both platforms, cost only on Claude.<br><br>**Example Analytics Questions:**<ul><li>Who are your most active users across both AI platforms?</li><li>How does a user's month-to-date usage compare to their lifetime usage?</li><li>How many active days has each user logged this month?</li></ul> |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

### Materialized Models

Each Quickstart transformation job run materializes the following model counts for each selected connector. The total model count represents all staging, intermediate, and final models, materialized as `view`, `table`, or `incremental`:

| **Connector** | **Model Count** |
| ------------- | --------------- |
| AI Reporting | 4 |
| [Claude](https://github.com/fivetran/dbt_claude) | 30 |
| [OpenAI](https://github.com/fivetran/dbt_openai) | 48 |

---

## Prerequisites
To use this dbt package, you must have the following:

- A Fivetran Claude/Anthropic connection **and** a Fivetran OpenAI connection both syncing data into your destination. This package is built to combine both platforms and does not support enabling only one.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, **Databricks**, or **DuckDB** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement).
- To add the package to your dbt project, follow the setup instructions below.

### Install the package
Include the following package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
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

### Disable models for non-existent sources
Your Claude or OpenAI connection might not sync every table this package expects. Disable the corresponding variable for any table you are not syncing so the package does not attempt to build models that depend on it.

#### Claude
By default, all variables are `true`. Disable only the tables you are not syncing:

```yml
vars:
    claude__using_cost_report: false                               # Disable if you do not have COST_REPORT synced.
    claude__using_enterprise_user_cost_report: false              # Disable if you do not have ENTERPRISE_USER_COST_REPORT synced.
    claude__using_message_usage_report: false                     # Disable if you do not have MESSAGE_USAGE_REPORT synced.
    claude__using_enterprise_user_usage_report: false             # Disable if you do not have ENTERPRISE_USER_USAGE_REPORT synced.
    claude__using_claude_code_usage_report: false                 # Disable if you do not have CLAUDE_CODE_USAGE_REPORT synced.
    claude__using_claude_code_usage_report_model_breakdown: false # Disable if you do not have CLAUDE_CODE_USAGE_REPORT_MODEL_BREAKDOWN synced.
    claude__using_users: false                                    # Disable if you do not have USERS synced.
    claude__using_enterprise_user_actor: false                    # Disable if you do not have ENTERPRISE_USER_ACTOR synced.
    claude__using_api_key: false                                  # Disable if you do not have API_KEY synced.
    claude__using_enterprise_user_activity: false                 # Disable if you do not have ENTERPRISE_USER_ACTIVITY synced.
    claude__using_organization: false                             # Disable if you do not have ORGANIZATION synced.
    claude__using_workspace: false                                # Disable if you do not have WORKSPACE synced.
    claude__using_workspace_member: false                         # Disable if you do not have WORKSPACE_MEMBER synced.
```

#### OpenAI
OpenAI accounts differ significantly in which tables they sync — nearly every table is optional. By default, all variables are `true`. Disable only the tables you are not syncing:

```yml
vars:
    openai_using_cost:                   false   # Disable if you are not syncing the cost table
    openai_using_completion:             false   # Disable if you are not syncing the completion table
    openai_using_embedding:              false   # Disable if you are not syncing the embedding table
    openai_using_audio_transcription:    false   # Disable if you are not syncing the audio_transcription table
    openai_using_audio_speech:           false   # Disable if you are not syncing the audio_speech table
    openai_using_image:                  false   # Disable if you are not syncing the image table
    openai_using_moderation:             false   # Disable if you are not syncing the moderation table
    openai_using_web_search_call:        false   # Disable if you are not syncing the web_search_call table
    openai_using_file_search_call:       false   # Disable if you are not syncing the file_search_call table
    openai_using_codex_usage:            false   # Disable if you are not syncing the codex_usage table
    openai_using_codex_usage_model:      false   # Disable if you are not syncing the codex_usage_model table
    openai_using_project:                false   # Disable if you are not syncing the project table
    openai_using_project_api_key:        false   # Disable if you are not syncing the project_api_key table
    openai_using_project_user:           false   # Disable if you are not syncing the project_user table
    openai_using_project_user_role:      false   # Disable if you are not syncing the project_user_role table
    openai_using_project_role:           false   # Disable if you are not syncing the project_role table
    openai_using_users_role:             false   # Disable if you are not syncing the users_role table
    openai_using_groups:                 false   # Disable if you are not syncing the groups table
    openai_using_invite:                 false   # Disable if you are not syncing the invite table
```

### (Optional) Additional configurations
<details open><summary>Expand/Collapse details</summary>

#### Passing through additional fields

Both upstream packages support bringing additional source columns through to their final models.

**Claude**

`claude__enterprise_user_activity_pass_through_metrics` adds numeric columns from the `ENTERPRISE_USER_ACTIVITY` source table. They are summed into `lifetime_<field>` and `month_to_date_<field>` columns in `claude__user_summary`, which flows through to `ai_reporting__user_summary`:

```yml
# dbt_project.yml

vars:
  claude__enterprise_user_activity_pass_through_metrics:
    - name: "that_field"
      alias: "renamed_to_this_field"
      transform_sql: "cast(renamed_to_this_field as string)"
    - name: "this_field"
```

**OpenAI**

The following variables bring additional columns from their respective source tables into OpenAI's final models. Each field is summed at every aggregation point between its source table and the reports it feeds:

```yml
# dbt_project.yml

vars:
    openai__cost_passthrough_metrics: []
    openai__completion_passthrough_metrics: []
    openai__codex_usage_passthrough_metrics: []
    openai__codex_usage_model_passthrough_metrics: []
    openai__compliance_cost_passthrough_metrics: []
    openai__compliance_cost_billing_passthrough_metrics: []
```

All six variables accept the same format:

```yml
vars:
  openai__completion_passthrough_metrics:
    - name: "field_id"
      alias: "field_name"
      transform_sql: "cast(field_name as int64)"
    - name: "another_field_name"
```

`name` is the column name as it appears in the raw source table. `alias` and `transform_sql` are optional. If both are set, `transform_sql` should reference the `alias`, not the raw `name`.

#### Model family overrides (OpenAI)

`openai__cost_usage_report` and `openai__enterprise_user_report` include `model_family` and `model_variant` alongside the original `model` string. When a model name does not match a recognized pattern, the full name becomes the family and `model_variant` is null. To override a model's parsed family:

```yml
vars:
  openai_model_family_overrides:
    gpt-4o-mini: gpt-4o-mini      # keep gpt-4o-mini snapshots under their own family instead of folding into gpt-4o
    codex-mini-latest: codex-mini # rename a specific model's family
```

Keys are the exact model name as it appears in your data (trimmed, lowercased, with any `ft:` fine-tune wrapper removed). Overrides take precedence over built-in parsing rules.

#### Change the source table references

If a source table has a different name in your destination than the package expects, set the identifier variable for that table.

**Claude:**
```yml
vars:
    claude_<default_source_table_name>_identifier: your_table_name
```
See [`src_claude.yml`](https://github.com/fivetran/dbt_claude/blob/main/models/staging/src_claude.yml) for the expected default names.

**OpenAI:**
```yml
vars:
    openai_<default_source_table_name>_identifier: your_table_name
```
See [`dbt_project.yml`](https://github.com/fivetran/dbt_openai/blob/main/dbt_project.yml) for the expected default names.

#### Changing the build schema

By default, this package builds its final models in a schema titled (`<target_schema>` + `_ai_reporting`). To change where these models are written, add the following to your root `dbt_project.yml`:

```yml
models:
    ai_reporting:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

The upstream Claude and OpenAI packages each build their own staging and intermediate schemas. To change those, add the following:

```yml
models:
    claude:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
    openai:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

See the [Claude](https://github.com/fivetran/dbt_claude/blob/main/README.md) and [OpenAI](https://github.com/fivetran/dbt_openai/blob/main/README.md) package READMEs for the default schema names for each.

#### Source casing for case-sensitive destinations

By default, the upstream packages apply case-insensitive comparisons when resolving `source_relation` values. If your destination is case-sensitive and you want downstream transformations to respect the exact casing of your source database and schema names, set the following variable:

```yml
vars:
    fivetran_using_source_casing: true
```

</details>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt/setup-guide#transformationsfordbtcoresetupguide).
</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/claude
      version: [">=0.1.0", "<0.2.0"]

    - package: fivetran/openai
      version: [">=0.1.0", "<0.2.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

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
