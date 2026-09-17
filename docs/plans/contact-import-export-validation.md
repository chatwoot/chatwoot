# Contact imports and exports: implementation handoff

Tracking: [CW-8215](https://linear.app/chatwoot/issue/CW-8215/unify-contact-imports-and-exports-under-settings-data)

Branch: `codex/cw-8215-contact-data-parity`, based on `5b7038b950b763e230df2d544df9b87b8752fef3`.

## Delivered behavior

- Settings → Data has working Import and Export tabs. Contacts actions open the matching Settings flow. Export shortcuts carry the current saved segment, filters, or label in a short-lived account-scoped session draft; missing drafts display an error and start no export.
- File upload supports contact CSVs. Active Storage stores the upload before preparation is queued; S3 installations use their configured storage service. Preparation validates the complete structure before contact changes begin.
- The CSV source uses the shared import job orchestration, run ownership, recovery, item journal, and diagnostic records. Each contact change, its labels, row outcome, and progress counter commit together. Replayed jobs skip successful items, and stale runs cannot publish changes.
- Matching contacts receive nonblank standard-field updates and merged custom fields. Conflicting identities and unknown labels reject the whole row. Validated writes suppress contact callbacks, webhooks, automations, live contact events, and company side effects. Completion and failure emails remain separate.
- Imports show preparation, processed totals, created/updated/failed counts, row errors, rejected-row downloads, abandon, and permitted recovery actions. Correct rejected rows and upload them as a new import. Escaped phone numbers from downloadable CSVs remain importable.
- Every export owns its selection, progress, status, attachment, and completion email. Generation streams in batches and protects CSV formulas. The query definition is saved at confirmation; contact values are read during execution. A rerun creates another export. Download authorization is checked before issuing a five-minute storage URL.
- CSV import/export access follows existing contact permissions, including Enterprise `contact_manage`. Integration imports still require an administrator and the `data_import` feature. Histories and downloads remain account scoped.
- The old Contacts API endpoints delegate to the new services. Legacy worker classes and queued argument contracts remain available to drain old jobs.
- File, row, and field limits are 50 MiB, 250,000 rows, and 1 MiB. One managed import runs per account; exports are independent. Daily cleanup expires terminal artifacts and staged personal data after 30 days while retaining summary history. Active operations are never purged.

## Verification

Backend regression command:

```sh
bundle exec rspec spec/services/data_imports spec/jobs/data_imports \
  spec/models/data_import_spec.rb spec/models/data_export_spec.rb \
  spec/requests/api/v1/accounts/data_imports_spec.rb \
  spec/requests/api/v1/accounts/contact_data_operations_spec.rb \
  spec/enterprise/requests/api/v1/accounts/contact_data_operations_spec.rb \
  spec/jobs/data_exports spec/jobs/internal/expire_data_operation_files_job_spec.rb \
  spec/controllers/api/v1/accounts/contacts_controller_spec.rb \
  spec/jobs/data_import_job_spec.rb spec/jobs/account/contacts_export_job_spec.rb \
  spec/jobs/internal/trigger_daily_scheduled_items_job_spec.rb \
  spec/services/contacts/filter_service_spec.rb
```

Result: 372 examples, zero failures, one pre-existing pending encryption example because local encryption keys were not configured. The tests cover API providers and legacy workers as well as CSV preparation, silent writes, recovery, row errors, encoding, limits, export scope, notifications, permission revocation, account isolation/deletion, and retention.

Dashboard checks: 25 tests pass across eight data-management suites. They cover integration and CSV dialogs, progress/status actions, polling cleanup, export draft isolation/expiration, and navigation with the real Settings route wrapper. The production Vite build and Rails autoload check pass. Changed Ruby files pass RuboCop; changed JavaScript/Vue files pass ESLint with only three pre-existing dynamic-translation warnings in the Contacts header. `git diff --check` passes.

Browser verification used a disposable local account with integration imports disabled. Confirmed Settings navigation, both histories, the contact export shortcut and confirmation, the file-only import modal, multipart CSV upload, queued status, completion through polling after execution of the actual queued CSV jobs, row counts and diagnostics, rejected-row download, and completed-export download. The final review repeated both Contacts shortcuts and checked the import dialog at a 390-pixel viewport.

Final review fixed a Settings query-navigation remount that discarded the active dialog and export selection, and added route-level regression coverage. It also tightened text-filter value validation while preserving the scalar-string format accepted by queued legacy exports, and removed the old Contacts dialogs after verifying they had no remaining callers.

Local load rehearsal: the streaming reader consumed 250,000 logical records (10,527,791 bytes) in 1.08 seconds. A separate 2,000-contact import staged in 0.11 seconds and completed contact writes in 10.27 seconds. These are development-machine measurements, not production throughput guarantees. Pending-item lookup has a partial index so later batches do not repeatedly scan successful rows.

## Release sequence

1. Apply the new `data_exports` table migration and the concurrent partial index on pending import items.
2. Deploy backend and workers that understand CSV source jobs and data exports before exposing the new dashboard bundle during a rolling deployment.
3. Keep legacy workers until pre-deployment CSV import and contact export jobs have drained. Do not relabel or dual-enqueue legacy pending imports.
4. Verify one contact CSV and one scoped export against the installation's configured storage service and confirm normal worker/email delivery. Live S3 credentials and delivery infrastructure were not exercised by the local tests.
5. Verify the daily scheduler runs artifact cleanup. Terminal source files, rejected rows, and export downloads expire after 30 days; history remains available.

Production rollout and live storage/email verification remain outstanding. The linked tracking issue records the current PR and delivery status.
