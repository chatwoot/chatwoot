# frozen_string_literal: true

class Integrations::Facebook::MessageCreator
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def perform
    # begin
    return process_reaction if response.reaction?

    if agent_message_via_echo?
      create_agent_message
    else
      create_contact_message
    end
    # rescue => e
    # ChatwootExceptionTracker.new(e).capture_exception
    # end
  end

  private

  def process_reaction
    target_message = Message.find_by(source_id: response.reaction_mid)
    return log_missing_reaction_target if target_message.blank?

    contact = reaction_contact(target_message.inbox)
    return if contact.blank?

    Messages::Reactions::UpsertService.new(
      account: target_message.account,
      inbox: target_message.inbox,
      conversation: target_message.conversation,
      message: target_message,
      sender: contact,
      actor_external_id: response.sender_id,
      source_id: reaction_source_id,
      external_message_id: response.reaction_mid,
      emoji: reaction_emoji,
      reaction_type: reaction_type,
      action: reaction_action,
      external_created_at: reaction_external_created_at
    ).perform
  end

  def reaction_contact(inbox)
    contact_inbox = inbox.contact_inboxes.find_by(source_id: response.sender_id)
    return contact_inbox.contact if contact_inbox.present?

    inbox.channel.create_contact_inbox(response.sender_id, "Unknown (FB: #{response.sender_id})").contact
  end

  def reaction_action
    response.reaction_action.to_sym
  end

  def reaction_emoji
    return nil if reaction_action == :unreact

    response.reaction_emoji
  end

  def reaction_type
    return nil if reaction_action == :unreact

    response.reaction_type
  end

  def reaction_source_id
    "#{response.reaction_mid}:#{response.sender_id}:#{response.time_stamp}"
  end

  def reaction_external_created_at
    Time.zone.at(response.time_stamp.to_i / 1000)
  end

  def log_missing_reaction_target
    Rails.logger.warn "Facebook Error: reaction target message not found - source_id: #{response.reaction_mid}"
  end

  def agent_message_via_echo?
    # TODO : check and remove send_from_chatwoot_app if not working
    response.echo? && !response.sent_from_chatwoot_app?
    # this means that it is an agent message from page, but not sent from chatwoot.
    # User can send from fb page directly on mobile / web messenger, so this case should be handled as agent message
  end

  def create_agent_message
    Channel::FacebookPage.where(page_id: response.sender_id).each do |page|
      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox, outgoing_echo: true)
      mb.perform
    end
  end

  def create_contact_message
    Channel::FacebookPage.where(page_id: response.recipient_id).each do |page|
      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox)
      mb.perform
    end
  end
end
