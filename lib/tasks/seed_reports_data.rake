# rubocop:disable Rails/Output, Metrics/BlockLength
namespace :db do
  namespace :seed do
    desc 'Seed test data for reports with conversations, contacts, agents, teams, and realistic reporting events'
    task reports_data: :environment do
      abort 'This task can only be run in development environment.' unless Rails.env.development?
      abort 'ENABLE_ACCOUNT_SEEDING must be set to true.' unless ENV['ENABLE_ACCOUNT_SEEDING'] == 'true'

      account = prompt_for_account
      config = prompt_for_config
      abort 'Seeding cancelled.' unless confirm_seeding(account)

      seeder = Seeders::Reports::ReportDataSeeder.new(account: account, config: config)
      seeder.perform!

      puts "Finished seeding reports data for account: #{account.name}"
    end

    def prompt(message)
      print "#{message}: "
      $stdin.gets.chomp
    end

    def prompt_with_default(message, default)
      input = prompt("#{message} (default: #{default})")
      input.blank? ? default : input.to_i
    end

    def prompt_for_account
      input = prompt('Enter Account ID')
      account = Account.find_by(id: input)
      abort "Account with ID #{input} not found." if account.nil?
      account
    end

    def prompt_for_config
      {
        total_conversations: prompt_with_default('Total conversations', 1000),
        total_contacts: prompt_with_default('Total contacts', 100),
        total_agents: prompt_with_default('Total agents', 20),
        total_teams: prompt_with_default('Total teams', 5),
        total_labels: prompt_with_default('Total labels', 30),
        days_range: prompt_with_default('Days of data to generate', 90)
      }
    end

    def confirm_seeding(account)
      puts "\nWARNING: This will DELETE all existing data for account '#{account.name}' (ID: #{account.id})"
      prompt('Are you sure you want to proceed? (yes/no)').downcase == 'yes'
    end
  end
end
# rubocop:enable Rails/Output, Metrics/BlockLength
