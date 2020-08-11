class Twitter::SendOnTwitterService < Base::SendOnChannelService
  pattr_initialize [:message!]

  private

  delegate :additional_attributes, to: :contact

  def channel_class
    Channel::TwitterProfile
  end

  def perform_reply
    conversation_type == 'tweet' ? send_tweet_reply : send_direct_message
  end

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_key = ENV.fetch('TWITTER_CONSUMER_KEY', nil)
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
      config.access_token = channel.twitter_access_token
      config.access_token_secret = channel.twitter_access_token_secret
      config.base_url = 'https://api.twitter.com'
      config.environment = ENV.fetch('TWITTER_ENVIRONMENT', '')
    end
  end

  def conversation_type
    conversation.additional_attributes['type']
  end

  def screen_name
    "@#{reply_to_message.sender&.additional_attributes.try(:[], 'screen_name') || ''}"
  end

  def send_direct_message
    twitter_client.send_direct_message(
      recipient_id: contact_inbox.source_id,
      message: message.content
    )
  end

  def reply_to_message
    @reply_to_message ||= if message.in_reply_to
                            conversation.messages.find(message.in_reply_to)
                          else
                            conversation.messages.incoming.last
                          end
  end

  def send_tweet_reply
    response = twitter_client.send_tweet_reply(
      reply_to_tweet_id: reply_to_message.source_id,
      tweet: "#{screen_name} #{message.content}"
    )
    if response.status == '200'
      tweet_data = response.body
      message.update!(source_id: tweet_data['id_str'])
    else
      Rails.logger.info 'TWITTER_TWEET_REPLY_ERROR' + response.body
    end
  end
end
