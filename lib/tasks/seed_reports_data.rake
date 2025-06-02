namespace :db do
  namespace :seed do
    desc 'Seed test data for reports with conversations, contacts, agents, teams, and realistic reporting events'
    task reports_data: :environment do
      if ENV['ACCOUNT_ID'].blank?
        puts 'Please provide an ACCOUNT_ID environment variable'
        puts 'Usage: ACCOUNT_ID=1 ENABLE_ACCOUNT_SEEDING=true bundle exec rake db:seed:reports_data'
        exit 1
      end

      ENV['ENABLE_ACCOUNT_SEEDING'] = 'true' if ENV['ENABLE_ACCOUNT_SEEDING'].blank?

      account_id = ENV.fetch('ACCOUNT_ID', nil)
      account = Account.find(account_id)

      puts "Starting reports data seeding for account: #{account.name} (ID: #{account.id})"

      seeder = Seeders::Reports::ReportDataSeeder.new(account: account)
      seeder.perform!

      puts "Finished seeding reports data for account: #{account.name}"
    end
  end
end
