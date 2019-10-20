# frozen_string_literal: true

class Integrations::Facebook::MessageCreator
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def perform
    # begin
    if outgoing_message_via_echo?
      create_outgoing_message
    else
      create_incoming_message
    end
    # rescue => e
    # Raven.capture_exception(e)
    # end
  end

  private

  def outgoing_message_via_echo?
    response.echo? && !response.sent_from_chatwoot_app?
    # this means that it is an outgoing message from page, but not sent from chatwoot.
    # User can send from fb page directly on mobile messenger, so this case should be handled as outgoing message
  end

  def create_outgoing_message
    Channel::FacebookPage.where(page_id: response.sender_id).each do |page|
      mb = Messages::Outgoing::EchoBuilder.new(response, page.inbox, true)
      mb.perform
    end
  end

  def create_incoming_message
    Channel::FacebookPage.where(page_id: response.recipient_id).each do |page|
      mb = Messages::IncomingMessageBuilder.new(response, page.inbox)
      mb.perform
    end
  end
end
