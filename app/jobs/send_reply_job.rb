class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s
    if channel_name == 'Channel::FacebookPage'
      ::Facebook::SendOnFacebookService.new(message: message).perform
    elsif channel_name == 'Channel::TwitterProfile'
      ::Twitter::SendOnTwitterService.new(message: message).perform
    elsif channel_name == 'Channel::TwilioSms'
      ::Twilio::SendOnTwilioService.new(message: message).perform
    end
  end
end
