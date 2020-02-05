class Twitter::TweetParserService < Twitter::WebhooksBaseService
  pattr_initialize [:payload]

  def perform
    set_inbox
    find_or_create_contact(user)
    set_conversation
    @conversation.messages.create(
      content: tweet_text,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      fb_id: tweet_data['id']
    )
  end

  private

  def message_type
    user['id'] == profile_id ? :outgoing : :incoming
  end

  def tweet_text
    tweet_data['truncated'] ? tweet_data['extended_tweet']['full_text'] : tweet_data['text']
  end

  def tweet_create_events_params
    payload['tweet_create_events']
  end

  def tweet_data
    tweet_create_events_params.first
  end

  def user
    tweet_data['user']
  end

  def parent_tweet_id
    tweet_data['in_reply_to_status_id_str'].nil? ? tweet_data['id'] : tweet_data['in_reply_to_status_id_str']
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        type: 'tweet',
        tweet_id: tweet_data['id_str'],
        tweet_source: tweet_data['source']
      }
    }
  end

  def set_conversation
    tweet_conversations = @contact_inbox.conversations.where("additional_attributes ->> 'tweet_id' = ?", tweet_data['id_str'])
    @conversation = tweet_conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end
end
