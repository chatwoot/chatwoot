# Pathors provisions an agent bot when an account connects the integration, and
# keeps its own record pointing back at that bot. The integration card's
# Disconnect is only one of the ways the bot can go away — the agent bots
# screen, the platform API and the console all destroy it directly — so the
# notification hangs off the record itself instead of a single controller.
# Without it Pathors keeps talking to a bot that no longer exists.
module Pathors::BotDisconnectNotifiable
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :notify_pathors_of_disconnect, if: :pathors_bot?
  end

  private

  def pathors_bot?
    outgoing_url&.include?(Integrations::App::PATHORS_CALLBACK_URL_FRAGMENT)
  end

  # Delivered through the agent bot webhook path, so the payload carries the
  # same signature headers Pathors already verifies with the bot's secret.
  # Enqueued rather than sent inline: the deletion must not wait on Pathors, and
  # a failed delivery must not take the destroy down with it.
  def notify_pathors_of_disconnect
    AgentBots::WebhookJob.perform_later(
      outgoing_url,
      { event: 'integration.disconnected', account_id: account_id },
      :agent_bot_webhook,
      secret: secret
    )
  end
end
