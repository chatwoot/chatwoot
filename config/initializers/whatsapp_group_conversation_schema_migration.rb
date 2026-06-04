Rails.application.config.after_initialize do
  next if Rails.env.test?
  next if ENV['SKIP_WHATSAPP_GROUP_SCHEMA_BOOTSTRAP'] == 'true'
  next unless defined?(Rails::Server) || (defined?(Sidekiq) && Sidekiq.server?)

  Whatsapp::GroupConversationSchemaMigrationJob.perform_later
end
