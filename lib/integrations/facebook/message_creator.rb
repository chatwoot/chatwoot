# frozen_string_literal: true

class Integrations::Facebook::MessageCreator
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def perform
    # begin
    if agent_message_via_echo?
      create_agent_message
    else
      create_contact_message
    end
    # rescue => e
    # Raven.capture_exception(e)
    # end
  end

  private

  def agent_message_via_echo?
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
