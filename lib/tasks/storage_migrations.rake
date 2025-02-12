namespace :storage do
  desc 'Migrate blobs from one storage service to another'
  task migrate: :environment do
    from_service = ENV.fetch('FROM', nil)
    to_service = ENV.fetch('TO', nil)

    raise 'Missing FROM or TO argument. Usage: FROM=service_name TO=service_name rake storage:migrate' if from_service.nil? || to_service.nil?

    ActiveStorage::Migrator.migrate(from_service.to_sym, to_service.to_sym)
  end
end
