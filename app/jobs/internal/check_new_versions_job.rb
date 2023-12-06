class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?

    instance_info = ChatwootHub.sync_with_hub
    return unless instance_info

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, instance_info['version'])
    config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
    config.value = instance_info['plan']
    config.locked = true
    config.save!
  end
end
