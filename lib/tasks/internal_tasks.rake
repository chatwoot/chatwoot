namespace :internal_tasks do
  desc 'Seed default task templates for all accounts'
  task seed_templates: :environment do
    Account.find_each do |account|
      TaskTemplates::DefaultSeeder.new(account: account).perform
      puts "Seeded task templates for account #{account.id} (#{account.name})"
    end
  end
end
