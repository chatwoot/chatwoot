class Webhooks::XEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 8

  def perform(event)
    @event = event.with_indifferent_access
    return if channel_is_inactive?

    process_event
  end

  private

  def channel_is_inactive?
    return true if channel.blank?
    return true unless channel.account.active?

    false
  end

  def process_event
    process_direct_messages if @event[:direct_message_events].present?
    process_tweets if @event[:tweet_create_events].present?
  end

  def process_direct_messages
    @event[:direct_message_events].each do |dm_event|
      next if dm_event[:message_create].blank?

      sender_id = dm_event.dig(:message_create, :sender_id)
      recipient_id = dm_event.dig(:message_create, :target, :recipient_id)

      key = format(::Redis::Alfred::X_MESSAGE_MUTEX, sender_id: sender_id, recipient_id: recipient_id)
      with_lock(key, 10.seconds) do
        X::IncomingMessageService.new(
          channel: channel,
          dm_event: dm_event,
          users: @event[:users]
        ).perform
      end
    end
  end

  def process_tweets
    @event[:tweet_create_events].each do |tweet_event|
      next if user_has_blocked?(tweet_event)

      next unless outgoing_tweet?(tweet_event) || mentions_channel?(tweet_event) || reply_to_channel_tweet?(tweet_event)

      process_tweet_event(tweet_event)
    end
  end

  def process_tweet_event(tweet_event)
    sender_id = tweet_event[:user][:id_str]

    key = format(::Redis::Alfred::X_MESSAGE_MUTEX, sender_id: sender_id, recipient_id: channel.profile_id)
    with_lock(key, 10.seconds) do
      X::IncomingMessageService.new(
        channel: channel,
        tweet_data: tweet_event
      ).perform
    end
  end

  def outgoing_tweet?(tweet_event)
    tweet_event[:user][:id_str] == channel.profile_id
  end

  def user_has_blocked?(tweet_event)
    tweet_event[:user_has_blocked] == true
  end

  def mentions_channel?(tweet_event)
    mentions = tweet_event.dig(:entities, :user_mentions) || []
    mentions.any? { |m| m[:id_str] == channel.profile_id || m[:id].to_s == channel.profile_id }
  end

  def reply_to_channel_tweet?(tweet_event)
    parent_tweet_id = tweet_event[:in_reply_to_status_id_str]
    return false if parent_tweet_id.blank?

    channel.inbox.messages.exists?(source_id: parent_tweet_id)
  end

  def channel
    @channel ||= Channel::X.find_by(profile_id: @event[:for_user_id])
  end
end
