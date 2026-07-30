class Migration::CopyCaptainAutoResolveModeToAssistantsJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Captain::Assistant.joins(:account).includes(:account).find_each do |assistant|
      assistant.with_lock do
        config = assistant.config.dup
        config['auto_resolve_mode'] = assistant.account.captain_auto_resolve_mode unless config.key?('auto_resolve_mode')
        config['auto_resolve_after'] = Captain::Assistant::DEFAULT_INACTIVITY_THRESHOLD_MINUTES unless config.key?('auto_resolve_after')
        config['send_inactivity_resolution_message'] = true unless config.key?('send_inactivity_resolution_message')

        next if config == assistant.config

        # rubocop:disable Rails/SkipsModelValidations
        assistant.update_columns(config: config)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
