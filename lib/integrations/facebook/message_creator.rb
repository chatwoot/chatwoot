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
      # Không tự động đánh dấu tin nhắn đã xem để tránh hiểu nhầm khi bot không hoạt động
      # mark_as_seen
    end
    # rescue => e
    # ChatwootExceptionTracker.new(e).capture_exception
    # end
  end

  private

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

  def mark_as_seen
    return if response.sender_id.blank?

    Channel::FacebookPage.where(page_id: response.recipient_id).each do |page|
      begin
        if page.blank? || page.page_access_token.blank?
          Rails.logger.warn "Cannot mark message as seen: Invalid Facebook page or missing access token for page_id: #{response.recipient_id}"
          next
        end

        typing_service = Facebook::TypingIndicatorService.new(page, response.sender_id)
        result = typing_service.mark_seen

        if result
          Rails.logger.info "Successfully marked message as seen for sender #{response.sender_id} on page #{page.page_id}"
        else
          Rails.logger.warn "Failed to mark message as seen for sender #{response.sender_id} on page #{page.page_id}"
        end
      rescue => e
        Rails.logger.error "Error marking message as seen on Facebook: #{e.message}"
      end
    end
  end
end
