class Instagram::CommentMessageService < Instagram::WebhooksBaseService
  def initialize(message, owner_instagram_id)
    @message = message
    @owner_instagram_id = owner_instagram_id
    super(channel)
  end

  def perform
    return if sender_id == @owner_instagram_id

    inbox_channel(@owner_instagram_id)
    ensure_contact(sender_id) if contacts_first_message?(sender_id)
    Messages::Instagram::CommentMessageBuilder.new(@message, @inbox).perform
    Messages::Instagram::ReplyCommentMessageBuilder.new(@message, @inbox).perform
  end

  private

  def ensure_contact(ig_scope_id)
    result = Instagram::FetchInstagramUserService.new(@inbox.id, ig_scope_id).perform
    find_or_create_contact(result) if result.present?
  end

  def sender_id
    @message.dig(:from, :id)
  end

  def channel
    Channel::Instagram.find_by(instagram_id: @owner_instagram_id)
  end

  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && @inbox.channel.instagram_id.present?
  end
end
