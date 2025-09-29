class Webhooks::WahaEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return if params[:isGroup] == true
    return if params[:event] == 'receipt' # Ignore read receipts and delivery reports

    channel = Channel::WhatsappUnofficial.find_by(phone_number: params[:phone_number])
    return unless channel

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    if params[:edited_text].present?
      Waha::UpdateMessageService.new(inbox: channel.inbox, params: params).perform
    elsif params[:isFromMe] == true
      Waha::StatusChangedService.new(inbox: channel.inbox, params: params).perform
    elsif params[:isFromMe] == false
      Waha::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    else
      Rails.logger.info "Unhandled WAHA event structure: #{params.inspect}"
      # Optionally, log or notify about the unhandled event for further investigation
    end
  end
end
