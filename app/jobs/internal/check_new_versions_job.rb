class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?

    instance_info = ChatwootHub.sync_with_hub
    return unless instance_info

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, instance_info['version'])
    update_installation_config(key: 'INSTALLATION_PRICING_PLAN', value: instance_info['plan'])
    update_installation_config(key: 'INSTALLATION_PRICING_PLAN_QUANTITY', value: instance_info['plan_quantity'])
    update_installation_config(key: 'CHATWOOT_SUPPORT_WEBSITE_TOKEN', value: instance_info['chatwoot_support_website_token'])
    update_installation_config(key: 'CHATWOOT_SUPPORT_IDENTIFIER_HASH', value: instance_info['chatwoot_support_identifier_hash'])
    update_installation_config(key: 'CHATWOOT_SUPPORT_SCRIPT_URL', value: instance_info['chatwoot_support_script_url'])
  end

  def update_installation_config(key:, value:)
    config = InstallationConfig.find_or_initialize_by(name: key)
    config.value = value
    config.locked = true
    config.save!
  end
end
