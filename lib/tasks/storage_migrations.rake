namespace :storage do
  desc 'Migrate blobs from one storage service to another'
  # Example: FROM=local TO=amazon UPDATE_BLOB_SERVICE_NAME=true bundle exec rake storage:migrate
  task migrate: :environment do
    from_service = ENV.fetch('FROM', nil)
    to_service = ENV.fetch('TO', nil)
    should_update_service_name = ActiveModel::Type::Boolean.new.cast(ENV.fetch('UPDATE_BLOB_SERVICE_NAME', true))

    raise 'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate' if from_service.nil? || to_service.nil?

    ActiveStorage::Migrator.migrate(from_service.to_sym, to_service.to_sym, should_update_service_name: should_update_service_name)
  end
end
