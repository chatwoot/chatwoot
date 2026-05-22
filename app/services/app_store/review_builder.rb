class AppStore::ReviewBuilder
  pattr_initialize [:review_payload!, :channel!]

  def perform
    return if review_id.blank? || review_body.blank?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_conversation
      upsert_review_message
      build_response_message if response_body.present?
    end
  end

  private

  def inbox
    @inbox ||= channel.inbox
  end

  def review
    @review ||= review_payload['review'] || {}
  end

  def response
    @response ||= review_payload['response'] || {}
  end

  def attributes
    @attributes ||= review['attributes'] || {}
  end

  def response_attributes
    @response_attributes ||= response['attributes'] || {}
  end

  def review_id
    review['id']
  end

  def review_body
    attributes['body'].to_s.strip
  end

  def review_title
    attributes['title'].to_s.strip
  end

  def rating
    attributes['rating'].to_i
  end

  def created_at
    Time.zone.parse(attributes['createdDate'].to_s)
  rescue StandardError
    Time.current
  end

  def response_id
    response['id']
  end

  def response_body
    response_attributes['responseBody'].to_s.strip
  end

  def response_created_at
    Time.zone.parse(response_attributes['lastModifiedDate'].to_s)
  rescue StandardError
    Time.current
  end

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: review_id,
      inbox: inbox,
      contact_attributes: {
        name: attributes['reviewerNickname'].presence || 'App Store User',
        additional_attributes: { source_id: "app_store:#{review_id}" }
      }
    ).perform
  end

  def build_conversation
    @conversation = @contact_inbox.conversations.last || ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: { source: 'app_store', app_id: channel.app_id }
    )
  end

  def upsert_review_message
    message = @conversation.messages.find_by(source_id: review_id)
    if message
      message.update!(content: message_content, content_attributes: review_metadata)
      return
    end

    @conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      sender: @conversation.contact,
      message_type: :incoming,
      source_id: review_id,
      content: message_content,
      content_attributes: review_metadata,
      created_at: created_at,
      updated_at: created_at
    )
  end

  def build_response_message
    return if response_id.blank?
    return if @conversation.messages.exists?(source_id: response_id)

    @conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :outgoing,
      source_id: response_id,
      content: response_body,
      status: :delivered,
      content_attributes: response_metadata,
      created_at: response_created_at,
      updated_at: response_created_at
    )
  end

  def message_content
    [
      rating_line,
      review_title.presence,
      review_body,
      review_footer
    ].compact_blank.join("\n\n")
  end

  def rating_line
    stars = ('★' * rating) + ('☆' * (5 - rating))
    "#{stars} (#{rating}/5)"
  end

  def review_footer
    parts = [attributes['territory'], attributes['reviewerNickname']].compact_blank
    return nil if parts.empty?

    parts.join(' • ')
  end

  def review_metadata
    {
      app_store: {
        rating: rating,
        title: review_title,
        territory: attributes['territory'],
        reviewer_nickname: attributes['reviewerNickname'],
        created_date: attributes['createdDate']
      }
    }
  end

  def response_metadata
    {
      app_store: {
        response_id: response_id,
        response_state: response_attributes['state'],
        response_last_modified_date: response_attributes['lastModifiedDate']
      }
    }
  end
end
