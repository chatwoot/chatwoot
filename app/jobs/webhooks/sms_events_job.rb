class Webhooks::SmsEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:type] == 'message-received'

    channel = Channel::Sms.find_by(phone_number: params[:to])
    return unless channel

    # TODO: pass to appropriate provider service from here
    Sms::IncomingMessageService.new(inbox: channel.inbox, params: params[:message].with_indifferent_access).perform
  end
end
