namespace :companies do
  desc 'Backfill companies from existing contact email domains'
  task backfill: :environment do
    puts 'Starting company backfill migration...'
    puts 'This will process all accounts and create companies from contact email domains.'
    puts 'The job will run in the background via Sidekiq'
    puts ''
    Migration::CompanyBackfillJob.perform_later
    puts 'Company backfill job has been enqueued.'
    puts 'Monitor progress in logs or Sidekiq dashboard.'
  end

  desc 'Fetch favicons for companies without avatars'
  task fetch_missing_avatars: :environment do
    account_ids = companies_without_avatars

    account_ids.each do |account_id|
      Companies::FetchAvatarsJob.perform_later(account_id)
    end

    puts "Queued #{account_ids.count} accounts for favicon fetch"
  end
end

def companies_without_avatars
  Company.left_joins(:avatar_attachment)
         .where(active_storage_attachments: { id: nil })
         .where.not(domain: [nil, ''])
         .distinct
         .pluck(:account_id)
end
