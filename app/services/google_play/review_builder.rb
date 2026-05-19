# Builds a contact, conversation and incoming message from a single Google Play review.
# Each review maps to one conversation (keyed on the review id). When a reviewer edits
# their review, a fresh incoming message is appended to the same conversation.
class GooglePlay::ReviewBuilder
  pattr_initialize [:review!, :channel!]

  def perform
    return if user_comment.blank? || review_text.blank?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_conversation
      build_message
    end
  end

  private

  def inbox
    @inbox ||= channel.inbox
  end

  def user_comment
    @user_comment ||= Array(review['comments']).filter_map { |comment| comment['userComment'] }.first
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
  def message_source_id
    "#{review_id}::#{user_comment.dig('lastModified', 'seconds')}"
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

  def build_message
    return if @conversation.messages.exists?(source_id: message_source_id)

    @conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      sender: @conversation.contact,
      message_type: :incoming,
      source_id: message_source_id,
      content: message_content,
      content_attributes: review_metadata
    )
  end

  def message_content
    stars = ('★' * star_rating) + ('☆' * (5 - star_rating))
    "#{stars} (#{star_rating}/5)\n\n#{review_text}"
  end

  def review_metadata
    {
      google_play: {
        star_rating: star_rating,
        app_version: user_comment['appVersionName'],
        device: user_comment['device'],
        reviewer_language: user_comment['reviewerLanguage']
      }
    }
  end
end
