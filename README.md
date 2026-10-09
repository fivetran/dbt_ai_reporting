<!--section="ai-reporting_transformation_model"-->
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
  - [DAG](https://fivetran.github.io/dbt_ai_reporting/#!/overview?g_v=1)
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
| [`ai_reporting__code_report`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__code_report) | One row per platform, source_relation, date_day, and user. Combines Claude Code and Codex CLI lines-of-code and token usage. Claude cost is always in USD when `claude__using_claude_code_usage_report_model_breakdown` is enabled; OpenAI's `estimated_cost` is null unless you set `openai__code_report_credit_rate` to convert its credits into an estimated USD figure, and OpenAI credits are always available in their own column.<br><br>**Example Analytics Questions:**<ul><li>Which developers are the heaviest users of AI coding assistants?</li><li>How does coding-assistant activity trend over time per user?</li><li>How much token volume is Claude Code driving compared to Codex CLI?</li></ul> |
| [`ai_reporting__enterprise_report`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__enterprise_report) | One row per platform, source_relation, date_day, actor, model, and product. Combines Claude and OpenAI enterprise (seat-level) usage; cost is populated only on Claude rows.<br><br>**Example Analytics Questions:**<ul><li>Which products (chat, Claude Code, etc.) are seeing the most usage per actor?</li><li>How does seat-level usage vary across models?</li><li>Which actors are the heaviest enterprise users on each platform?</li></ul> |
| [`ai_reporting__user_summary`](https://fivetran.github.io/dbt_ai_reporting/#!/model/model.ai_reporting.ai_reporting__user_summary) | One row per platform, source_relation, and user. Combines lifetime and month-to-date usage summaries; tokens and active days are populated on both platforms, cost only on Claude.<br><br>**Example Analytics Questions:**<ul><li>Who are your most active users across both AI platforms?</li><li>How does a user's month-to-date usage compare to their lifetime usage?</li><li>How many active days has each user logged this month?</li></ul> |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

### Materialized Models

Each Quickstart transformation job run materializes the following model counts for each selected connector. The total model count represents all staging, intermediate, and final models, materialized as `view`, `table`, or `incremental`:

| **Connector** | **Model Count** |
| ------------- | --------------- |
| AI Reporting | 4 |
| [Claude](https://github.com/fivetran/dbt_claude) | 30 |
| [OpenAI](https://github.com/fivetran/dbt_openai) | 49 |

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Claude/Anthropic connection **or** Fivetran OpenAI connection syncing data into your destination. Each platform's models are conditionally enabled, so the package builds with only one platform active.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, **Databricks**, or **DuckDB** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_ai_reporting/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

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

### Disable models for non-existent sources
Your Claude or OpenAI connection might not sync every table this package expects. Disable the corresponding variable for any table you are not syncing so the package does not attempt to build models that depend on it. By default, all variables are `true`.

```yml
vars:
    ## Claude
    claude__using_cost_report: false                              # Disable if you do not have COST_REPORT synced.
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

    ## OpenAI
    openai__using_cost:                   false   # Disable if you are not syncing the cost table
    openai__using_completion:             false   # Disable if you are not syncing the completion table
    openai__using_embedding:              false   # Disable if you are not syncing the embedding table
    openai__using_audio_transcription:    false   # Disable if you are not syncing the audio_transcription table
    openai__using_audio_speech:           false   # Disable if you are not syncing the audio_speech table
    openai__using_image:                  false   # Disable if you are not syncing the image table
    openai__using_moderation:             false   # Disable if you are not syncing the moderation table
    openai__using_web_search_call:        false   # Disable if you are not syncing the web_search_call table
    openai__using_file_search_call:       false   # Disable if you are not syncing the file_search_call table
    openai__using_codex_usage:            false   # Disable if you are not syncing the codex_usage table
    openai__using_codex_usage_model:      false   # Disable if you are not syncing the codex_usage_model table
    openai__using_project:                false   # Disable if you are not syncing the project table
    openai__using_project_api_key:        false   # Disable if you are not syncing the project_api_key table
    openai__using_project_user:           false   # Disable if you are not syncing the project_user table
    openai__using_project_user_role:      false   # Disable if you are not syncing the project_user_role table
    openai__using_users_role:             false   # Disable if you are not syncing the users_role table
    openai__using_invite:                 false   # Disable if you are not syncing the invite table
    openai__using_compliance_cost:        false   # Disable if you are not syncing Compliance Platform cost data
    openai__using_compliance_users:       false   # Disable if you are not syncing the Compliance Platform users table
```

### Changing the build schema

By default, this package builds its final AI Reporting models in a schema titled (`<target_schema>` + `_ai_reporting`). The upstream [Claude](https://github.com/fivetran/dbt_claude#changing-the-build-schema) and [OpenAI](https://github.com/fivetran/dbt_openai#changing-the-build-schema) packages each build their own staging schemas titled (`<target_schema>` + `_claude/openai_staging`) and transform schemas titled (`<target_schema>` + `_claude/openai_reports`).

To change where these models are written, add the following to your root `dbt_project.yml`:

```yml
models:
    ai_reporting:
      +schema: ai_reporting # Default suffix. Leave +schema: blank to use the default target_schema.
    claude:
      +schema: claude_reports # Default suffix
      staging:
        +schema: claude_staging # Default suffix
    openai:
      +schema: openai_reports # Default suffix
      staging:
        +schema: openai_staging # Default suffix
```

### (Optional) Additional configurations
<details open><summary>Expand/Collapse details</summary>

#### Configure cent-to-dollar conversion (Claude)

The Claude API reports cost fields such as `amount` and `estimated_cost_amount` in the smallest denomination of the currency — cents, or fractional cents on some endpoints, for USD. By default, this package divides those fields by 100 in staging so every downstream cost column is in major currency units (dollars for USD).

This conversion applies only to Claude rows. OpenAI cost is already reported in major currency units and is not affected by this setting.

If you prefer to keep Claude cost fields in their raw, undivided form, set `claude__convert_cost` to `false` in your `dbt_project.yml`:

```yml
vars:
    claude__convert_cost: false # default is true
```

#### Estimate OpenAI Codex cost in USD
`ai_reporting__code_report` leaves `estimated_cost` null on OpenAI rows by default, since OpenAI's Codex credits have no published USD conversion rate. If you want an approximate USD figure anyway, set your own credits-to-dollars rate:
```yml
# dbt_project.yml

vars:
  openai__code_report_credit_rate: 0.04 # your own credits-to-USD rate; estimated_cost = credits * openai__code_report_credit_rate
```
This is a customer-supplied estimate, not a value OpenAI publishes -- see [DECISIONLOG.md](https://github.com/fivetran/dbt_ai_reporting/blob/main/DECISIONLOG.md) for context.

#### Model family overrides (OpenAI)

`openai__cost_usage_report` and `openai__enterprise_user_report` include `model_family` and `model_variant` alongside the original `model` string. When a model name does not match a recognized pattern, the full name becomes the family and `model_variant` is null. To override a model's parsed family:

```yml
vars:
  openai_model_family_overrides:
    - model: gpt-4o-mini        # keep gpt-4o-mini snapshots under their own family instead of folding into gpt-4o
      family: gpt-4o-mini
    - model: codex-mini-latest  # rename a specific model's family
      family: codex-mini
```

Keys are the exact model name as it appears in your data (trimmed, lowercased, with any `ft:` fine-tune wrapper removed). Overrides take precedence over built-in parsing rules.

#### Passing through additional fields

Both upstream packages support bringing additional source columns through to their **platform-specific** transform models (not the combined `ai_reporting__*` models). Their variables accept the same format:

```yml
# dbt_project.yml

vars:
  pass_through_metric_var:
    - name: "that_field"
      alias: "renamed_to_this_field"
      transform_sql: "cast(renamed_to_this_field as string)"
    - name: "this_field"
    - name: "other_field"
      transform_sql: "other_field / 100.0"
```

`name` is the column name as it appears in the raw source table. `alias` and `transform_sql` are optional. If both are set, `transform_sql` should reference the `alias`, not the raw `name`.

**Claude**

`claude__enterprise_user_activity_pass_through_metrics` adds numeric columns from the `ENTERPRISE_USER_ACTIVITY` source table. They are summed into `lifetime_<field>` and `month_to_date_<field>` columns in `claude__user_summary`:

```yml
# dbt_project.yml

vars:
  claude__enterprise_user_activity_pass_through_metrics: [] # Default = empty
```

**OpenAI**

Each OpenAI variable brings in columns from one source table and feeds them into a specific OpenAI transform model, aggregated as needed to reach that model's grain:

| Variable | Source table | End model | Aggregation |
| --- | --- | --- | --- |
| `openai__cost_passthrough_metrics` | `cost` | `openai__cost_usage_report` | Summed |
| `openai__completion_passthrough_metrics` | `completion` | `openai__cost_usage_report` | Summed |
| `openai__codex_usage_passthrough_metrics` | `codex_usage` | `openai__code_report` | None (already at report grain) |
| `openai__codex_usage_model_passthrough_metrics` | `codex_usage_model` | `openai__code_report` | Summed |
| `openai__compliance_cost_passthrough_metrics` | `compliance_costs_organization_log` | `openai__compliance_cost_report` | None (constant per event; read with `max`) |
| `openai__compliance_cost_billing_passthrough_metrics` | `compliance_costs_organization_log_billing` | `openai__compliance_cost_report` | Summed |

```yml
# dbt_project.yml

vars:
    openai__cost_passthrough_metrics: [] # Default = empty
    openai__completion_passthrough_metrics: [] # Default = empty
    openai__codex_usage_passthrough_metrics: [] # Default = empty
    openai__codex_usage_model_passthrough_metrics: [] # Default = empty
    openai__compliance_cost_passthrough_metrics: [] # Default = empty
    openai__compliance_cost_billing_passthrough_metrics: [] # Default = empty
```

#### Change the source table references

If a source table has a different name in your destination than the package expects, set the identifier variable for that table.

```yml
vars:
    claude_<default_source_table_name>_identifier: your_table_name

    openai_<default_source_table_name>_identifier: your_table_name
```
See [`src_claude.yml`](https://github.com/fivetran/dbt_claude/blob/main/models/staging/src_claude.yml) and [`src_openai.yml`](https://github.com/fivetran/dbt_openai/blob/main/models/staging/src_openai.yml) for the expected default names.

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
      version: [">=0.4.12", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

<!--section="ai_reporting_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/ai_reporting/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_ai_reporting/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Opinionated Decisions
Building a package that combines two independently designed source packages required a few opinionated calls, for example how we handle Claude's USD cost alongside OpenAI's non-USD credit unit, and how we roll up Claude Code's grain to match Codex CLI's. We've documented these choices in [DECISIONLOG.md](https://github.com/fivetran/dbt_ai_reporting/blob/main/DECISIONLOG.md) and welcome feedback on them.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_ai_reporting/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
