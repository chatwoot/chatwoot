module Enterprise::Concerns::IntegrationsHook
  extend ActiveSupport::Concern

  included do
    before_destroy :clear_monitor_slack_channels, if: :slack?
  end

  private

  # A saved channel belongs to the disconnected workspace, so it must not carry over to the next connection.
  def clear_monitor_slack_channels
    ConversationMonitors::Monitor.where(account_id: account_id).update_all(slack_channel_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end
end
