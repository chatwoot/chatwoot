class Integrations::Slack::SendContactUpdateService
  # Conversations linked to a Slack thread store the Slack message `ts`
  # (e.g. "1693292344.123456") in `identifier`; other channels reuse the same
  # column for non-Slack values such as Twilio call SIDs.
  SLACK_THREAD_TS_FORMAT = '^\d+\.\d+$'.freeze

  # Errors that mean every subsequent post would fail the same way, so the
  # hook is disabled and the conversation loop aborted.
  FATAL_SLACK_ERRORS = [
    Slack::Web::Api::Errors::IsArchived,
    Slack::Web::Api::Errors::AccountInactive,
    Slack::Web::Api::Errors::MissingScope,
    Slack::Web::Api::Errors::InvalidAuth,
    Slack::Web::Api::Errors::ChannelNotFound,
    Slack::Web::Api::Errors::NotInChannel
  ].freeze

  pattr_initialize [:contact!, :hook!, :changed_attributes!]

  def perform
    return if contact.email.blank?

    active_conversations_with_slack_integration.each do |conversation|
      send_contact_update_to_slack(conversation)
    end
  rescue *FATAL_SLACK_ERRORS => e
    Rails.logger.error e
    hook.prompt_reauthorization!
    hook.disable
  end

  private

  def active_conversations_with_slack_integration
    @active_conversations_with_slack_integration ||= contact.conversations
                                                            .where(status: %w[open pending])
                                                            .where('conversations.identifier ~ ?', SLACK_THREAD_TS_FORMAT)
  end

  def send_contact_update_to_slack(conversation)
    slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: contact_update_message,
      thread_ts: conversation.identifier,
      unfurl_links: false
    )
  rescue *FATAL_SLACK_ERRORS
    raise
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error "Failed to send contact update to Slack: #{e.message}"
  end

  def contact_update_message
    @contact_update_message ||= begin
      old_email, new_email = changed_attributes['email']

      if old_email.present?
        "📧 Contact email updated: #{old_email} → #{new_email}"
      else
        "📧 Contact email added: #{new_email}"
      end
    end
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
