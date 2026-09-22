class ConversationMonitors::BroadcastJob < ApplicationJob
  queue_as :low

  def self.schedule(monitor_id)
    return unless Redis::Alfred.set("conversation_monitors:broadcast:#{monitor_id}", '1', nx: true, ex: 3)

    set(wait: 2.seconds).perform_later(monitor_id)
  rescue StandardError => e
    Rails.logger.error("Conversation monitor broadcast enqueue failed: #{e.class.name}")
  end

  def perform(monitor_id)
    # Release the coalescing window before reading so later results can queue another update.
    Redis::Alfred.delete("conversation_monitors:broadcast:#{monitor_id}")
    monitor = ConversationMonitors::Monitor.visible.find_by(id: monitor_id)
    return unless monitor&.account&.feature_enabled?('conversation_monitors')

    tokens = monitor.account.account_users.includes(:user, :custom_role).filter_map do |membership|
      context = { user: membership.user, account: monitor.account, account_user: membership }
      membership.user.pubsub_token if ReportPolicy.new(context, :report).view?
    end
    return unless tokens.any?

    ActionCableBroadcastJob.perform_later(tokens, 'monitor.updated', {
                                            account_id: monitor.account_id, monitor_id: monitor.id, data_revision: monitor.data_revision
                                          })
  end
end
