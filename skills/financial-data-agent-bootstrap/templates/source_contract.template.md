# Source Contract

## Source Overview

- Source name：`<source-name>`
- Source type：`<Wind/Oracle/Excel workbook/Mail raw archive/Web API/Local CSV/Parquet/other>`
- Business purpose：`<business-purpose>`
- Owner：`<owner-name-or-role>`
- Credential boundary：`<where credentials are managed; do not paste secrets>`
- Source freshness expectation：`<freshness-rule>`
- Human confirmation required：`<yes/no + items>`

## Shared Rules

- Identifier rules：`<symbol/id/account/product/code semantics>`
- Timestamp / timezone / date semantics：`<as-of/trade/value/report date + timezone>`
- Unit conventions：`<currency/percentage/bps/notional/share/unit>`
- Null / missing source behavior：`<stop/warn/fill/manual-review>`
- Retry / failure evidence：`<logs/status/counts/manifest/error-summary>`
- Sensitive-data constraints：`<redaction-and-reporting-rule>`
- Source-target reconciliation：`<reconciliation-method>`

## Wind Source

- Identifier namespace：`<wind-code-or-placeholder>`
- Trading calendar：`<calendar-rule>`
- Date parameters：`<date-field-rule>`
- Field list owner：`<owner-or-doc-path>`
- Unit conventions：`<price/rate/amount/unit-rule>`
- Batching / rate limit：`<batch-size/rate-policy>`
- Fallback / retry：`<retry-or-stop-rule>`
- Freshness check：`<latest-date-or-source-timestamp-rule>`
- Sensitive constraints：`<no-credential-no-private-mapping>`

## Oracle Source

- Connection boundary：`<secret-manager-or-local-config-placeholder>`
- Schema / table identifier rule：`<placeholder-only>`
- Query ownership：`<doc-or-owner>`
- Timestamp / timezone rule：`<rule>`
- Pagination / batching：`<limit/chunk-key/range-rule>`
- Transaction / isolation note：`<read-only-or-authorized-write-rule>`
- Failure evidence：`<query-id/log-summary/counts>`
- Freshness check：`<watermark-or-max-date-rule>`
- Sensitive constraints：`<no-DSN-no-password-no-private-table-dump>`

## Excel Workbook Source

- Workbook identity rule：`<template-or-input-contract>`
- Sheet identity rule：`<sheet-placeholder>`
- Header row rule：`<row-or-named-range>`
- Date semantics：`<as-of/report/value-date-rule>`
- Unit conventions：`<currency/percent/bps/unit-rule>`
- Manual refresh dependency：`<yes/no + owner>`
- Failure evidence：`<sheet-list/schema-summary/hash/redacted-sample>`
- Sensitive constraints：`<no-raw-workbook-commit>`

## Mail Raw Archive Source

- Archive identity rule：`<mailbox-or-archive-placeholder>`
- Message selection rule：`<date/sender/subject/attachment-rule-placeholder>`
- Attachment handling：`<metadata-only/redacted-sample/no-raw-commit>`
- Timestamp / timezone rule：`<received/sent/as-of-rule>`
- Deduplication rule：`<message-id/hash/rule>`
- Failure evidence：`<counts/hash/manifest/error-summary>`
- Sensitive constraints：`<no-raw-attachment-no-private-mail-content>`

## Web/API Source

- Endpoint identity rule：`<provider-doc-reference-placeholder>`
- Authentication boundary：`<secret-manager-or-env-placeholder>`
- Pagination / batching：`<page-token/offset/date-window-rule>`
- Rate limit：`<limit-and-backoff-rule>`
- Timestamp / timezone rule：`<source-timestamp-rule>`
- Retry / fallback：`<retry-budget-and-stop-rule>`
- Freshness check：`<watermark-or-response-time-rule>`
- Sensitive constraints：`<no-token-no-cookie-no-private-url>`

## Local CSV/Parquet Source

- File identity rule：`<directory-placeholder-and-pattern>`
- Schema owner：`<owner-or-contract>`
- Partition rule：`<date/product/other>`
- Encoding / compression：`<rule>`
- Timestamp / timezone rule：`<rule>`
- Incremental detection：`<manifest/hash/watermark-rule>`
- Failure evidence：`<file-count/hash/schema-summary>`
- Sensitive constraints：`<no-private-export-no-sensitive-mapping-table>`
