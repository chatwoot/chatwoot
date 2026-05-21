namespace :search do
  desc 'Reindex messages for all accounts'
  task all: :environment do
    next unless check_opensearch_config

    puts 'Starting reindex for all accounts...'
    account_count = Account.count
    puts "Found #{account_count} accounts"

    Account.find_each.with_index(1) do |account, index|
      puts "[#{index}/#{account_count}] Reindexing messages for account #{account.id}"
      reindex_account(account)
    end

    puts 'Reindex task queued for all accounts'
  end

  desc 'Reindex messages for a specific account: rake search:account ACCOUNT_ID=1'
  task account: :environment do
    next unless check_opensearch_config

    account_id = ENV.fetch('ACCOUNT_ID', nil)
    account = Account.find_by(id: account_id)
    if account.nil?
      puts 'Please provide a valid account ID. Account not found'
      next
    end
    puts "Reindexing messages for account #{account.id}"
    reindex_account(account)
  end
end

def check_opensearch_config
  if ENV['OPENSEARCH_URL'].blank?
    puts 'Skipping reindex as OPENSEARCH_URL is not configured'
    return false
  end
  true
end

def reindex_account(account)
  Messages::ReindexService.new(account: account).perform
  puts "Reindex task queued for account #{account.id}"
end
