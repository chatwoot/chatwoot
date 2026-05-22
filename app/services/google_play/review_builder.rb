# Builds a contact, conversation and messages from a single Google Play review.
# Each review maps to one conversation (keyed on the review id). When a reviewer edits
# their review, a fresh incoming message is appended to the same conversation.
# Developer replies (whether posted via Chatwoot or directly in Play Console) are mirrored
# as outgoing messages, with a source_id that matches what `SendOnGooglePlayService`
# produces so Chatwoot-originated replies are deduped on the next poll.
class GooglePlay::ReviewBuilder
  pattr_initialize [:review!, :channel!]

  def perform
    return if user_comment.blank? || review_text.blank?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_conversation
      build_user_message
      build_developer_message if developer_comment.present?
    end
  end

  private

  def inbox
    @inbox ||= channel.inbox
  end

  def user_comment
    @user_comment ||= comments_with_key('userComment').first
  end

  def developer_comment
    @developer_comment ||= comments_with_key('developerComment').first
  end

  def comments_with_key(key)
    Array(review['comments']).filter_map { |comment| comment[key] }
  end

  def review_id
    review['reviewId']
  end

  def review_text
    @review_text ||= user_comment['text'].to_s.strip
  end

  def star_rating
    @star_rating ||= user_comment['starRating'].to_i
  end

  # A new lastModified timestamp (edited review) yields a new message in the same conversation
  def user_message_source_id
    "#{review_id}::#{user_comment.dig('lastModified', 'seconds')}"
  end

  # Must match the format `Channel::GooglePlay#reply_to_review` returns so replies sent through
  # Chatwoot are not duplicated when the review is re-fetched.
  def developer_message_source_id
    "#{review_id}::reply::#{developer_comment.dig('lastModified', 'seconds')}"
  end

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: review_id,
      inbox: inbox,
      contact_attributes: {
        name: review['authorName'].presence || 'Google Play User',
        additional_attributes: { source_id: "google_play:#{review_id}" }
      }
    ).perform
  end

  def build_conversation
    @conversation = @contact_inbox.conversations.last || ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: { source: 'google_play', app_id: channel.app_id }
    )
  end

  def build_user_message
    return if @conversation.messages.exists?(source_id: user_message_source_id)

    @conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      sender: @conversation.contact,
      message_type: :incoming,
      source_id: user_message_source_id,
      content: message_content,
      content_attributes: review_metadata
    )
  end

  def build_developer_message
    text = developer_comment['text'].to_s.strip
    return if text.blank?
    return if @conversation.messages.exists?(source_id: developer_message_source_id)

    @conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :outgoing,
      source_id: developer_message_source_id,
      content: text,
      status: :sent
    )
  end

  def message_content
    stars = ('★' * star_rating) + ('☆' * (5 - star_rating))
    [
      "#{stars} (#{star_rating}/5)",
      review_text,
      review_footer
    ].compact_blank.join("\n\n")
  end

  # A compact line of context shown beneath the review text — device, app version, OS.
  def review_footer
    parts = [device_display, app_version_display, os_version_display].compact_blank
    return nil if parts.empty?

    parts.join(' • ')
  end

  def device_display
    metadata = user_comment['deviceMetadata'] || {}
    metadata['productName'].presence || user_comment['device']
  end

  def app_version_display
    version = user_comment['appVersionName']
    version.present? ? "v#{version}" : nil
  end

  def os_version_display
    version = user_comment['androidOsVersion']
    version.present? ? "Android #{version}" : nil
  end

  def review_metadata
    metadata = user_comment['deviceMetadata'] || {}
    {
      google_play: {
        star_rating: star_rating,
        app_version: user_comment['appVersionName'],
        device: device_display,
        manufacturer: metadata['manufacturer'],
        android_os_version: user_comment['androidOsVersion'],
        reviewer_language: user_comment['reviewerLanguage']
      }
    }
  end
end
