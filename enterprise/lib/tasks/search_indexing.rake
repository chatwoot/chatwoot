namespace :search do # rubocop:disable Metrics/BlockLength
  desc 'Backfill contacts or conversations: ENTITY=contacts [ACCOUNT_ID=1]'
  task backfill: :environment do
    entity = ENV.fetch('ENTITY')
    SearchIndexing::Registry::DOCUMENTS.fetch(entity)
    if ENV['ACCOUNT_ID'].present?
      state = SearchIndexing::Backfill.start(account: Account.find(ENV.fetch('ACCOUNT_ID')), entity: entity)
      puts "Started search backfill #{state.id}: #{entity} / account #{state.account_id}"
    else
      SearchIndexing::StartBackfillsJob.perform_later(entity)
    end
  end

  desc 'Inspect search backfill progress: [ACCOUNT_ID=1]'
  task indexing_status: :environment do
    states = SearchIndexing::IndexState.all
    states = states.where(account_id: ENV.fetch('ACCOUNT_ID')) if ENV['ACCOUNT_ID'].present?
    states.find_each do |state|
      puts state.attributes.slice('id', 'account_id', 'entity', 'status', 'phase', 'cursor', 'scanned_count', 'repaired_count', 'ready_at')
      puts state.buffer.statistics
    end
  end

  desc 'Pause a search backfill: STATE_ID=1'
  task pause_backfill: :environment do
    SearchIndexing::IndexState.find(ENV.fetch('STATE_ID')).pause!
  end

  desc 'Resume a search backfill: STATE_ID=1'
  task resume_backfill: :environment do
    SearchIndexing::IndexState.find(ENV.fetch('STATE_ID')).resume!
  end

  desc 'Retry one page of failed writes after fixing the cause: STATE_ID=1 [CURSOR=0]'
  task retry_failed_writes: :environment do
    state = SearchIndexing::IndexState.find(ENV.fetch('STATE_ID'))
    cursor, count = state.buffer.retry_failed(cursor: ENV.fetch('CURSOR', '0'))
    puts "Requeued #{count} writes; next CURSOR=#{cursor}. Resume the backfill once all failed writes have been requeued."
  end
end
