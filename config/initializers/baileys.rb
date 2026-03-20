Rails.application.config.after_initialize do
  next unless defined?(Sidekiq::CLI)

  Channels::Whatsapp::BaileysConnectionCheckSchedulerJob.perform_later
end
