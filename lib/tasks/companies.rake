namespace :companies do
  desc 'Backfill companies from existing contact email domains'
  task backfill: :environment do
    unless defined?(Migration::CompanyBackfillJob)
      puts 'This task is available only in Enterprise Edition.'
      next
    end

    puts 'Starting company backfill migration...'
    puts 'This will process all accounts and create companies from contact email domains.'
    puts 'The job will run in the background via Sidekiq'
    puts ''
    Migration::CompanyBackfillJob.perform_later
    puts 'Company backfill job has been enqueued.'
    puts 'Monitor progress in logs or Sidekiq dashboard.'
  end
end

namespace :companies do
  desc 'Fetch favicons for companies without avatars'
  task fetch_missing_avatars: :environment do
    unless defined?(Company) && defined?(Companies::FetchAvatarsJob)
      puts 'This task is available only in Enterprise Edition.'
      next
    end

    account_ids = Company.left_joins(:avatar_attachment)
                         .where(active_storage_attachments: { id: nil })
                         .where.not(domain: [nil, ''])
                         .distinct
                         .pluck(:account_id)

    account_ids.each do |account_id|
      Companies::FetchAvatarsJob.perform_later(account_id, force_refresh: false)
    end

    puts "Queued #{account_ids.count} accounts for favicon fetch"
  end
end

namespace :companies do
  desc 'Refresh favicons for all companies'
  task refresh_avatars: :environment do
    unless defined?(Company) && defined?(Companies::FetchAvatarsJob)
      puts 'This task is available only in Enterprise Edition.'
      next
    end

    account_ids = Company.where.not(domain: [nil, ''])
                         .distinct
                         .pluck(:account_id)

    account_ids.each do |account_id|
      Companies::FetchAvatarsJob.perform_later(account_id, force_refresh: true)
    end

    puts "Queued #{account_ids.count} accounts for favicon refresh"
  end
end
