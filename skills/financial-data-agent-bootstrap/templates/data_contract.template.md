# Data Contract

## Dataset Identity

- Dataset name：`<dataset-name>`
- Business purpose：`<business-purpose>`
- Data domain：`<data-domain>`
- Owner：`<owner-name-or-role>`
- Reviewer：`<reviewer-name-or-role>`
- Human confirmation required：`<yes/no + items>`

## Systems

- Source system：`<source-system-placeholder>`
- Target system：`<target-system-placeholder>`
- Environment：`<dev/test/prod/other>`
- Output artifact：`<artifact-type-and-placeholder-path>`
- Archive / manifest rule：`<manifest-or-audit-trail-policy>`

## Product Universe

- Product universe：`<product-universe-description>`
- Inclusion rule：`<inclusion-rule>`
- Exclusion rule：`<exclusion-rule>`
- Sensitive product mapping boundary：`<redacted-or-private-location>`

## Keys And Dates

- Primary key：`<field-list>`
- Natural key：`<field-list-or-none>`
- Date field：`<date-field>`
- Date semantics：`<trade-date/value-date/as-of-date/report-date/other>`
- Timezone：`<timezone-or-not-applicable>`
- Incremental rule：`<incremental-load-rule>`
- Full-refresh rule：`<full-refresh-rule-and-authorization-required>`

## Schema

| Field | Type | Required | Nullable | Unit | Description | Sensitive |
| --- | --- | --- | --- | --- | --- | --- |
| `<field-name>` | `<type>` | `<yes/no>` | `<yes/no>` | `<unit>` | `<meaning>` | `<yes/no>` |

## Required Fields

- `<required-field-1>`
- `<required-field-2>`

## Nullable Fields

- `<nullable-field-1>`: `<reason>`
- `<nullable-field-2>`: `<reason>`

## Duplicate Handling

- Duplicate definition：`<duplicate-definition>`
- Allowed duplicates：`<yes/no + condition>`
- Resolution rule：`<dedupe-or-stop-rule>`
- Evidence required：`<count/hash/manifest/validation-summary>`

## Missing Data Handling

- Missing source rows：`<stop/warn/fill/manual-review>`
- Missing required fields：`<stop/warn/fill/manual-review>`
- Fill rule：`<fill-rule-or-not-allowed>`
- Human confirmation required：`<yes/no + condition>`

## Illegal Value Handling

- Illegal value checks：`<range/list/sign/null/date-order-checks>`
- Failure action：`<stop/warn/quarantine/manual-review>`

## Sensitive Fields

- Sensitive field list：`<field-placeholders>`
- Redaction rule：`<redaction-rule>`
- Evidence allowed in reports：`<counts/schema/hash/manifest/redacted-sample/summary>`

## Validation Baseline

- Expected row count：`<range-or-source-dependent>`
- Expected date range：`<min/max-rule>`
- Expected product coverage：`<coverage-rule>`
- Source-target reconciliation：`<method>`
- Idempotency expectation：`<rule>`

## Approval

- Data owner confirmation：`<pending/confirmed>`
- Business owner confirmation：`<pending/confirmed>`
- Compliance / risk confirmation：`<pending/not-required/confirmed>`
