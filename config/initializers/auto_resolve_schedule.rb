require 'sidekiq/cron/job'

Sidekiq::Cron::Job.create(
  name: 'Auto Resolve Idle Conversations - every 2 minutes',
  cron: '*/2 * * * *',
  class: 'AutoResolveIdleConversationsJob'
)
