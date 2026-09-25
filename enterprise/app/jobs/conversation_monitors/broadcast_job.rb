class ConversationMonitors::BroadcastJob < ApplicationJob
  queue_as :low

  def self.schedule(monitor_id)
    return unless Redis::Alfred.set("conversation_monitors:broadcast:#{monitor_id}", '1', nx: true, ex: 3)

    set(wait: 2.seconds).perform_later(monitor_id)
  rescue StandardError => e
    Rails.logger.error("Conversation monitor broadcast enqueue failed: #{e.class.name}")
  end

  def perform(monitor_id, tombstone = nil)
    # Release the coalescing window before reading so later results can queue another update.
    Redis::Alfred.delete("conversation_monitors:broadcast:#{monitor_id}")
    context = broadcast_context(monitor_id, tombstone)
    return unless context

    account, payload = context
    return unless account && ConversationMonitors::Configuration.enabled?(account)

    tokens = account.account_users.includes(:user, :custom_role).filter_map do |membership|
      context = { user: membership.user, account: account, account_user: membership }
      membership.user.pubsub_token if ReportPolicy.new(context, :report).view?
    end
    return unless tokens.any?

    ActionCableBroadcastJob.perform_later(tokens, 'monitor.updated', payload)
  end

  private

  def broadcast_context(monitor_id, tombstone)
    return [Account.find_by(id: tombstone[:account_id]), tombstone] if tombstone

    monitor = ConversationMonitors::Monitor.find_by(id: monitor_id)
    return unless monitor

    payload = { account_id: monitor.account_id, monitor_id: monitor.id, data_revision: monitor.data_revision }
    payload[:deleted] = true if monitor.deleted_at
    [monitor.account, payload]
  end
end
