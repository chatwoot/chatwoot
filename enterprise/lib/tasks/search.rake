namespace :search do
  desc 'Reindex messages using searchkick'

  desc 'Reindex messages for all accounts'
  task all: :environment do
    if ENV['OPENSEARCH_URL'].blank?
      puts 'Skipping reindex as OPENSEARCH_URL is not configured'
      next
    end

    puts 'Starting reindex for all accounts...'
    account_count = Account.count
    puts "Found #{account_count} accounts"

    Account.find_each.with_index(1) do |account, index|
      puts "[#{index}/#{account_count}] Reindexing messages for account #{account.id}"
      Messages::ReindexService.new(account).perform
    end

    puts 'Reindex task queued for all accounts'
  end

  desc 'Reindex messages for a specific account: rake search:account ACCOUNT_ID=1'
  task account: :environment do
    if ENV['OPENSEARCH_URL'].blank?
      puts 'Skipping reindex as OPENSEARCH_URL is not configured'
      next
    end

    account_id = ENV['ACCOUNT_ID']
    if account_id.blank?
      puts 'Please provide an ACCOUNT_ID environment variable'
      next
    end

    account = Account.find_by(id: account_id)
    if account.nil?
      puts "Account with ID #{account_id} not found"
      next
    end

    puts "Reindexing messages for account #{account.id}"
    Messages::ReindexService.new(account).perform
    puts "Reindex task queued for account #{account.id}"
  end
end
