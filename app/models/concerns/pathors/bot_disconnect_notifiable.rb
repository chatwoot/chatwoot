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
    after_destroy_commit :clear_pathors_integration_hook, if: :pathors_bot?
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

  # The OAuth hook is the other half of the connection. A hook left without a
  # bot is what the integration card reads as "connection incomplete" — an amber
  # state the administrator cannot clear from the page — so every route that
  # removes the bot has to take the hook with it for the card to fall back to
  # "not connected".
  #
  # The card's own Disconnect destroys both in one transaction, which commits
  # before this runs: the relation is already empty then and destroy_all is a
  # no-op, so that path is unaffected. Destroying hooks touches no agent bots,
  # so there is no recursion back into this callback.
  #
  # A local delete, so it runs inline rather than through a job. The bot is
  # already gone by commit time and cannot be rolled back, so a failure here is
  # logged rather than raised — it must not take the destroy down with it.
  def clear_pathors_integration_hook
    account.hooks.where(app_id: 'pathors').destroy_all
  rescue StandardError => e
    Rails.logger.error("Failed to remove the Pathors integration hook: #{e.message}")
  end
end
