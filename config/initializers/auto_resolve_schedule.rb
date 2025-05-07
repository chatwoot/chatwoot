require 'sidekiq/cron/job'

Rails.application.config.after_initialize do
  if Sidekiq.server?
    Sidekiq::Cron::Job.create(
      name: 'Auto Resolve Idle Conversations - every 2 minutes',
      cron: '*/2 * * * *',
      class: 'AutoResolveIdleConversationsJob'
    )
  end
end
