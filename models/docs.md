{% docs platform %}
The AI vendor this row came from: `claude` or `openai`.
{% enddocs %}

{% docs source_relation %}
The specific source object this record originated from. Used for multi-connection deployments; see the [Connecting a package to multiple connections in the same schema](https://fivetran.com/docs/transformations/dbt/best-practices) documentation for more details.
{% enddocs %}

{% docs date_day %}
The calendar day this record's usage or cost was reported for.
{% enddocs %}

{% docs model %}
The specific model version used, as reported by the vendor (e.g. `claude-opus-4-1-20250805`, `gpt-4o-2024-08-06`).
{% enddocs %}

{% docs model_family %}
The model line the specific model version belongs to (e.g. `opus`, `gpt-4o`), independent of dated release.
{% enddocs %}

{% docs model_variant %}
The size or speed variant of the model family, when the vendor names one (e.g. `mini`, `haiku`).
{% enddocs %}

{% docs currency %}
The ISO currency code the cost figure on this row is denominated in.
{% enddocs %}

{% docs user_id %}
The vendor's unique identifier for the user this record is attributed to.
{% enddocs %}
