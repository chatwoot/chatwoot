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
end
