# frozen_string_literal: true

#rails db:seed_pipeline_statuses
namespace :db do
  desc 'Seed default pipeline statuses for all accounts'
  task seed_pipeline_statuses: :environment do
    puts '🌱 Seeding default pipeline statuses...'
    default_statuses = %w[new contacted proposal_sent closed].freeze

    Account.includes(:conversations).find_each do |account|
      default_statuses.each do |status_name|
        pipeline_status = account.pipeline_statuses.find_or_initialize_by(name: I18n.t("pipeline_status.default_statuses.#{status_name}"))
        if pipeline_status.new_record?
          pipeline_status.save!
          puts "✅ Created '#{status_name}' for Account ##{account.id}"
        else
          puts "⚠️ '#{status_name}' already exists for Account ##{account.id}"
        end
      end

      first_status_pipeline = account.pipeline_statuses.first
      account.conversations.each do |conversation|
        conversation.update!(pipeline_status: first_status_pipeline)
        puts "✅ Conversation with the id '#{conversation.id}' was updated"

      rescue StandardError => e
        puts "⚠️ Error trying to update the Conversation with the id #{conversation.id}"
        puts "⚠️ Error:  #{e.message}"
      end

      puts '🎉 Seeding completed!'
    end
  end
end
