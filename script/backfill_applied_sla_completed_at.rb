# Backfill applied_slas.completed_at from conversation resolution reporting events.
#
# Account-scoped dry run:
#   ACCOUNT_ID=168154 bundle exec rails runner script/backfill_applied_sla_completed_at.rb
#
# Account-scoped apply:
#   ACCOUNT_ID=168154 APPLY=true bundle exec rails runner script/backfill_applied_sla_completed_at.rb
#
# Explicit global apply with resume controls:
#   ALL_ACCOUNTS=true APPLY=true BATCH_SIZE=500 AFTER_ID=0 \
#     bundle exec rails runner script/backfill_applied_sla_completed_at.rb

begin
  account_id = Integer(ENV.fetch('ACCOUNT_ID'), 10) if ENV['ACCOUNT_ID'].present?
  all_accounts = ENV['ALL_ACCOUNTS'] == 'true'
  apply = ENV['APPLY'] == 'true'
  batch_size = Integer(ENV.fetch('BATCH_SIZE', Sla::BackfillAppliedSlaCompletedAtService::DEFAULT_BATCH_SIZE.to_s), 10)
  after_id = Integer(ENV.fetch('AFTER_ID', '0'), 10)

  Sla::BackfillAppliedSlaCompletedAtService.new(
    account_id: account_id,
    all_accounts: all_accounts,
    apply: apply,
    batch_size: batch_size,
    after_id: after_id
  ).perform
rescue ArgumentError, ActiveRecord::RecordNotFound => e
  warn "Backfill aborted: #{e.message}"
  exit 1
end
