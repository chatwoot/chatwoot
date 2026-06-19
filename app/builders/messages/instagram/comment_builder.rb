class Messages::Instagram::CommentBuilder
  def initialize(comment, inbox)
    @comment = comment.with_indifferent_access
    @inbox = inbox
  end

  def perform
    return if @inbox.channel.reauthorization_required?
    return if message_already_exists?

    ActiveRecord::Base.transaction do
      conversation.messages.create!(message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
  end

  private

  def contact
    @contact ||= contact_inbox&.contact
  end

  def contact_inbox
    @contact_inbox ||= @inbox.contact_inboxes.find_by(source_id: commenter_id)
  end

  def conversation
    @conversation ||= find_open_conversation || build_conversation
  end

  # Group all comments from the same media + contact into a single conversation,
  # keeping comment threads separate from direct-message conversations.
  # additional_attributes is a `json` column, so we match in Ruby instead of
  # relying on the Postgres `->>` operator (unreliable here).
  def find_open_conversation
    @inbox.conversations
          .where(contact_id: contact.id)
          .where.not(status: :resolved)
          .order(created_at: :desc)
          .find { |conv| conv.additional_attributes['instagram_media_id'] == media_id }
  end

  def build_conversation
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: {
        type: 'instagram_comment',
        instagram_media_id: media_id
      }
    )
  end

  def message_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      status: :sent,
      source_id: comment_id,
      content: comment_text,
      sender: contact,
      content_attributes: {
        type: 'instagram_comment',
        instagram_comment_id: comment_id,
        instagram_media_id: media_id,
        instagram_parent_comment_id: @comment[:parent_id]
      }
    }
  end

  def message_already_exists?
    Message.find_by(source_id: comment_id).present?
  end

  def commenter_id
    @comment.dig(:from, :id).to_s
  end

  def comment_id
    @comment[:id]
  end

  def media_id
    @comment.dig(:media, :id)
  end

  def comment_text
    @comment[:text]
  end
end
