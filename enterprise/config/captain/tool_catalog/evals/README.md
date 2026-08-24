# Captain Tool Catalog selection evaluation

This versioned evaluation compares the same 105 customer-support intents against a 15-tool baseline and a 50-tool candidate set. The candidate contains every currently model-visible catalog tool plus realistic support-tool distractors.

Validate the dataset and toolsets without making model calls:

```bash
bundle exec rake captain:tool_catalog:validate_evaluation
```

Run the live evaluation with the installation's configured Captain model, or override it explicitly:

```bash
MODEL=gpt-4.1-mini OUTPUT=tmp/captain-tool-catalog-eval.json \
  bundle exec rake captain:tool_catalog:evaluate
```

The command writes one JSON report containing prompt digests rather than prompt text. It exits unsuccessfully when any release check fails:

- At least 100 unique intents must complete in both runs.
- The tool counts must be exactly 15 and 50.
- Correct selection at 50 tools may decline by no more than five percentage points.
- Provider/input-schema rejections, planned-tool exposure, cross-customer identity arguments, and runner errors must be zero.

The `captain_tool_catalog_50_tool_beta` feature flag must remain disabled until a report from the release model passes. Enabling `captain_tool_catalog` alone keeps the account limit at 15.
