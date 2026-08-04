class Migration::CopyCaptainAutoResolveModeToAssistantsJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Captain::Assistant.includes(:account).find_each do |assistant|
      assistant.with_lock do
        next if assistant.config.key?('auto_resolve_mode')

        config = assistant.config.merge('auto_resolve_mode' => assistant.account.captain_auto_resolve_mode)
        assistant.update!(config: config)
      end
    end
  end
end
