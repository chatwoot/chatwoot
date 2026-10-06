module Enterprise::Concerns::IntegrationsHook
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :clear_monitor_slack_channels, if: :slack?
  end

  private

  # A saved channel belongs to the disconnected workspace, so it must not carry over to the next connection.
  def clear_monitor_slack_channels
    # rubocop:disable Rails/SkipsModelValidations
    ConversationMonitors::Monitor.where(account_id: account_id).where.not(slack_channel_id: nil)
                                 .update_all(slack_channel_id: nil, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
