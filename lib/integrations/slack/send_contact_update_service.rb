class Integrations::Slack::SendContactUpdateService
  pattr_initialize [:contact!, :hook!, :changed_attributes!]

  def perform
    return if contact.email.blank?
    return unless active_conversations_with_slack_integration.any?

    active_conversations_with_slack_integration.each do |conversation|
      send_contact_update_to_slack(conversation)
    end
  end

  private

  def active_conversations_with_slack_integration
    @active_conversations_with_slack_integration ||= contact.conversations
                                                            .where(status: %w[open pending])
                                                            .where.not(identifier: [nil, ''])
  end

  def send_contact_update_to_slack(conversation)
    return if conversation.identifier.blank?

    slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: contact_update_message,
      thread_ts: conversation.identifier,
      unfurl_links: false
    )
  rescue Slack::Web::Api::Errors::IsArchived, Slack::Web::Api::Errors::AccountInactive, Slack::Web::Api::Errors::MissingScope,
         Slack::Web::Api::Errors::InvalidAuth,
         Slack::Web::Api::Errors::ChannelNotFound, Slack::Web::Api::Errors::NotInChannel => e
    Rails.logger.error e
    hook.prompt_reauthorization!
    hook.disable
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error "Failed to send contact update to Slack: #{e.message}"
  end

  def contact_update_message
    old_email = changed_attributes['email'][0]
    new_email = changed_attributes['email'][1]

    if old_email.present?
      "📧 Contact email updated: #{old_email} → #{new_email}"
    else
      "📧 Contact email added: #{new_email}"
    end
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
