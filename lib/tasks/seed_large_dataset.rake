namespace :db do
  namespace :seed do
    desc 'Seed a large dataset with 10K conversations, 1K contacts, 200 agents, 8 teams, and 50 labels'
    task large_dataset: :environment do
      if ENV['ACCOUNT_ID'].blank?
        puts 'Please provide an ACCOUNT_ID environment variable'
        puts 'Usage: ACCOUNT_ID=1 ENABLE_ACCOUNT_SEEDING=true bundle exec rake db:seed:large_dataset'
        exit 1
      end

      ENV['ENABLE_ACCOUNT_SEEDING'] = 'true' unless ENV['ENABLE_ACCOUNT_SEEDING'].present?
      
      account_id = ENV['ACCOUNT_ID']
      account = Account.find(account_id)
      
      puts "Starting large dataset seeding for account: #{account.name} (ID: #{account.id})"
      
      seeder = Seeders::LargeDatasetSeeder.new(account: account)
      seeder.perform!
      
      puts "Finished seeding large dataset for account: #{account.name}"
    end
  end
end
