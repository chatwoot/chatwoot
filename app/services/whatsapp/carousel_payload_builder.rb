class Whatsapp::CarouselPayloadBuilder
  CTA_URL_TYPE = 'url'.freeze
  QUICK_REPLY_TYPE = 'reply'.freeze

  def initialize(message)
    @message = message
  end

  def perform
    validate_message!

    {
      type: 'carousel',
      body: {
        text: body_text
      },
      action: {
        cards: cards
      }
    }
  end

  private

  attr_reader :message

  def validate_message!
    unless message.inbox.whatsapp?
      raise CustomExceptions::Whatsapp::InvalidInteractivePayload,
            'Interactive carousel messages are only supported for WhatsApp inboxes'
    end
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Carousel body text is required' if body_text.blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Carousel items are required' if items.blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive carousel messages require at least 2 cards' if items.size < 2

    validate_card_media!
  end

  # WhatsApp interactive media carousels require every card to include an
  # image/video header; a blank media_url is otherwise silently dropped by
  # build_header's .compact, letting Chatwoot accept a payload the provider rejects.
  def validate_card_media!
    return if items.all? { |item| item.with_indifferent_access[:media_url].present? }

    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Carousel cards require a media_url'
  end

  def body_text
    message.content_attributes['body_text'].presence || message.outgoing_content
  end

  def items
    @items ||= message.content_attributes['items'] || []
  end

  def cards
    items.each_with_index.map do |item, index|
      build_card(item, index)
    end
  end

  def build_card(item, index)
    item = item.with_indifferent_access
    action_type = card_action_type(item)

    {
      card_index: index,
      type: action_type == CTA_URL_TYPE ? 'cta_url' : 'button',
      header: build_header(item),
      body: {
        text: format_card_body(item)
      },
      action: build_card_action(item, action_type)
    }.compact
  end

  def card_action_type(item)
    Array(item[:actions]).first&.with_indifferent_access&.[](:type)
  end

  def build_header(item)
    return if item[:media_url].blank?

    {
      type: 'image',
      image: {
        link: item[:media_url]
      }
    }
  end

  def format_card_body(item)
    [item[:title].presence, item[:description].presence].compact.join("\n\n")
  end

  def build_card_action(item, action_type)
    actions = Array(item[:actions]).map(&:with_indifferent_access)

    if action_type == CTA_URL_TYPE
      build_cta_url_action(actions.first)
    else
      build_quick_reply_action(actions)
    end
  end

  def build_cta_url_action(action)
    {
      name: 'cta_url',
      parameters: {
        display_text: action[:text],
        url: action[:uri]
      }
    }
  end

  def build_quick_reply_action(actions)
    {
      buttons: actions.map do |action|
        {
          type: 'quick_reply',
          quick_reply: {
            id: action[:payload],
            title: action[:text]
          }
        }
      end
    }
  end
end
