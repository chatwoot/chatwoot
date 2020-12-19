class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s
    case channel_name
    when 'Channel::FacebookPage'
      ::Facebook::SendOnFacebookService.new(message: message).perform
    when 'Channel::TwitterProfile'
      ::Twitter::SendOnTwitterService.new(message: message).perform
    when 'Channel::TwilioSms'
      ::Twilio::SendOnTwilioService.new(message: message).perform
    end
  end
end
