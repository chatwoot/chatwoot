class Instagram::Messenger::PostbackService < Instagram::WebhooksBaseService
  def initialize(messaging, channel)
    @messaging = messaging
    super(channel)
  end

  def perform
    instagram_id = @messaging[:recipient][:id]
    contact_id   = @messaging[:sender][:id]

    inbox_channel(instagram_id)
    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping postback processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    ensure_contact(contact_id)
    create_message
  end

  private

  def ensure_contact(ig_scope_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
    result = k&.get_object(ig_scope_id) || {}
    find_or_create_contact(result.with_indifferent_access) if result.present?
  rescue Koala::Facebook::ClientError, StandardError => e
    Rails.logger.warn("[InstagramMessengerPostbackError]: #{e.message}")
  end

  def conversation
    @conversation ||= find_or_build_conversation
  end

  def find_or_build_conversation
    Conversation.where(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id
    ).where.not(status: :resolved).order(created_at: :desc).first || build_conversation
  end

  def build_conversation
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: { type: 'instagram_direct_message' }
    )
  end

  def create_message
    return unless @contact_inbox

    postback_title = @messaging.dig(:postback, :title).presence || 'Postback'

    conversation.messages.create!(
      message_type: :incoming,
      content: postback_title,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      sender: @contact
    )
  end
end
