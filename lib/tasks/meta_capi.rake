namespace :meta_capi do
  # CTWA revenue backfill: re-emits Meta CAPI events for CRM cards that transitioned
  # before the sync was enabled. Idempotent — a transition already `accepted` in the
  # ledger is skipped, so re-running is safe.
  #
  # DRY-RUN BY DEFAULT: it only reports what WOULD be sent, without sending or writing.
  # Pass dry_run=false to actually enqueue Crm::MetaCapi::DispatchJob (source:'backfill').
  #
  #   bundle exec rails "meta_capi:backfill[123]"          # dry-run (default) for account 123
  #   bundle exec rails "meta_capi:backfill[123,false]"    # real run — enqueues dispatches
  desc 'Backfill Meta CAPI CTWA revenue events for an account (dry-run by default)'
  task :backfill, %i[account_id dry_run] => :environment do |_task, args|
    account_id = args[:account_id].to_i
    dry_run = args[:dry_run].to_s.downcase != 'false'

    report = Crm::MetaCapi::BackfillJob.new.perform(account_id, dry_run: dry_run)

    puts "[meta_capi:backfill] account=#{account_id} dry_run=#{dry_run} " \
         "would_send=#{report[:would_send]} skipped_no_clid=#{report[:skipped_no_clid]} " \
         "already_sent=#{report[:already_sent]} enqueued=#{report[:enqueued]} " \
         "by_event_type=#{report[:by_event_type].to_h}"
  end
end
