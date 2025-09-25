# frozen_string_literal: true

class AppleMessagesForBusiness::TypingIndicatorService
  def initialize(inbox:, params:, headers: {}, status: nil)
    @inbox = inbox
    @params = params
    @headers = headers
    @status = status
  end

  def perform
    # For now, we'll just log typing indicators
    # In the future, this could be used to show typing indicators in Chatwoot UI
    Rails.logger.info "Apple Messages typing indicator: #{@params['type']} from #{source_id}"
  end

  private

  def source_id
    @params['sourceId']
  end
end