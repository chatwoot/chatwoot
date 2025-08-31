# frozen_string_literal: true

namespace :wsc do
  namespace :staging do
    desc "Reset staging database and reseed with demo data"
    task reset: :environment do
      unless Rails.env.staging?
        puts "ERROR: This task can only be run in staging environment"
        exit 1
      end

      puts "🔄 Resetting staging database..."
      
      # Drop and recreate database
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      
      # Seed demo data
      puts "🌱 Seeding demo data..."
      Rake::Task['wsc:staging:seed'].invoke
      
      puts "✅ Staging reset complete!"
    end

    desc "Seed staging with demo tenants and data"
    task seed: :environment do
      unless Rails.env.staging?
        puts "ERROR: This task can only be run in staging environment"
        exit 1
      end

      puts "🏢 Creating demo accounts..."
      
      # Create demo accounts
      demo_accounts = [
        {
          name: "WeaveCode Demo Ltd",
          locale: "en_GB",
          domain: "weavecode-demo.com",
          support_email: "support@weavecode-demo.com"
        },
        {
          name: "Acme Corp UK",
          locale: "en_GB", 
          domain: "acme-uk.com",
          support_email: "help@acme-uk.com"
        },
        {
          name: "London SME Solutions",
          locale: "en_GB",
          domain: "london-sme.co.uk", 
          support_email: "contact@london-sme.co.uk"
        }
      ]

      demo_accounts.each_with_index do |account_data, index|
        account = Account.create!(account_data)
        puts "✅ Created account: #{account.name} (ID: #{account.id})"

        # Create admin user for each account
        user = User.create!(
          name: "Admin User #{index + 1}",
          email: "admin#{index + 1}@weavecode.demo",
          password: "DemoPassword123!",
          confirmed_at: Time.current
        )

        # Add user to account as administrator
        AccountUser.create!(
          account: account,
          user: user,
          role: "administrator"
        )

        puts "✅ Created admin user: #{user.email}"

        # Create demo inbox
        inbox = account.inboxes.create!(
          name: "Website Chat",
          channel_type: "Channel::WebWidget"
        )

        puts "✅ Created inbox: #{inbox.name}"
      end

      puts "🎉 Demo seeding complete!"
      puts "Demo accounts created with admin credentials:"
      puts "  admin1@weavecode.demo / DemoPassword123!"  
      puts "  admin2@weavecode.demo / DemoPassword123!"
      puts "  admin3@weavecode.demo / DemoPassword123!"
    end
  end
end