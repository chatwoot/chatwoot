class Zalo::CreateMessageService

  pattr_initialize :channel, :params

  TEXT_MESSAGE_EVENTS = %w[
    user_send_text
    oa_send_text
  ]

  ATTACHMENT_EVENTS = %w[
    user_send_image
    oa_send_image
    user_send_file
    oa_send_file
    user_send_gif
    oa_send_gif
    user_send_audio
  ]

  CARD_EVENTS = %w[
    user_send_business_card
  ]

  STICKER_EVENTS = %w[
    user_send_sticker
    oa_send_sticker
  ]

  LOCATION_EVENTS = %w[
    user_send_location
  ]

  ALL_EVENTS = TEXT_MESSAGE_EVENTS + ATTACHMENT_EVENTS + STICKER_EVENTS + CARD_EVENTS + LOCATION_EVENTS


  def process
    inbox.with_lock do
      set_contact
      set_conversation
      hanle_message
    end
  end

  private

  attr_reader :channel, :params

  def hanle_message
    case params[:event_name]
    when *TEXT_MESSAGE_EVENTS
      Zalo::Messages::TextService.new(@conversation, params).process
    when *ATTACHMENT_EVENTS
      Zalo::Messages::AttachmentService.new(@conversation, params).process
    when *STICKER_EVENTS
      Zalo::Messages::StickerService.new(@conversation, params).process
    when *CARD_EVENTS
      Zalo::Messages::BusinessCardService.new(@conversation, params).process
    when *LOCATION_EVENTS
      Zalo::Messages::LocationService.new(@conversation, params).process
    else
      Rails.logger.warn("Unhandled Zalo event type: #{params[:event_name]}")
    end
  end

  def account
    @account ||= channel.account
  end

  def inbox
    @inbox ||= channel.inbox
  end

  def contact_key
    return @contact_key if defined?(@contact_key)

    sender_id = params.dig(:sender, :id)
    recipient_id = params.dig(:recipient, :id)
    @contact_key = sender_id == channel.oa_id ? recipient_id : sender_id
  end

  def set_contact
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: contact_key)
    if @contact_inbox.nil?
      contact_info = Integrations::Zalo::User.new(channel.access_token).detail(contact_key)
      contact_info = contact_info.with_indifferent_access
      @contact_inbox = ::ContactInboxWithContactBuilder.new(
        inbox: inbox,
        source_id: contact_key,
        contact_attributes: {
          identifier: contact_key,
          name: contact_info.dig(:data, :display_name) || contact_info.dig(:data, :user_alias),
          avatar_url: contact_info.dig(:data, :avatar),
          custom_attributes: {
            platform: :zalo,
            shared_info: contact_info.dig(:data, :shared_info),
          },
        },
      ).perform
    end
    @contact = @contact_inbox.contact
  end

  def set_conversation
    @conversation ||= @contact_inbox.conversations.unresolved.last
    @conversation ||= inbox.conversations.create!(
      account_id: account.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
    )
  end
end
