# frozen_string_literal: true

# rails db:seed_contact_pipeline_statuses
namespace :db do
  desc 'Seed default contact pipeline status for all accounts'
  task seed_contact_pipeline_statuses: :environment do
    puts 'Seeding contact pipeline statuses...'

    Account.find_each do |account|
      unless account.pipeline_statuses.exists?(pipeline_type: 'contact')
        account.pipeline_statuses.create!(name: 'nuevo', pipeline_type: 'contact', position: 1)
      end

      default_status = account.pipeline_statuses.where(pipeline_type: 'contact').order(:position).first
      account.contacts.where(pipeline_status_id: nil).update_all(pipeline_status_id: default_status.id) # rubocop:disable Rails/SkipsModelValidations
    end

    puts 'Done!'
  end
end
