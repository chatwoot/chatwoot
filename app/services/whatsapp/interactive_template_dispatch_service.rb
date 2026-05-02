# frozen_string_literal: true

# Sends a saved WhatsappInteractiveTemplate as a message to a conversation.
# Builds the runtime payload via InteractiveTemplatePayloadBuilder and creates a
# Message with the right shape for the WhatsApp Cloud sender to dispatch:
#   - cta_url / quick_replies: content_type=integrations + content_attributes.interactive
#   - rich_text: plain text message with the body composed in-line
class Whatsapp::InteractiveTemplateDispatchService
  class DispatchError < StandardError; end

  def initialize(template:, conversation:, user:, runtime_url: nil, runtime_body_text: nil)
    @template = template
    @conversation = conversation
    @user = user
    @runtime_url = runtime_url
    @runtime_body_text = runtime_body_text
  end

  def perform
    raise DispatchError, 'Conversation must belong to a WhatsApp inbox' unless whatsapp_conversation?

    payload = built_payload
    raise DispatchError, 'Static URL is required for direct dispatch' if cta_url_missing_static?(payload)

    @conversation.messages.create!(message_attributes(payload))
  rescue Whatsapp::InteractiveTemplatePayloadBuilder::ValidationError => e
    raise DispatchError, e.message
  rescue ActiveRecord::RecordInvalid => e
    raise DispatchError, e.message
  end

  private

  def built_payload
    Whatsapp::InteractiveTemplatePayloadBuilder.new(
      template: @template,
      runtime_url: @runtime_url,
      runtime_body_text: @runtime_body_text
    ).build
  end

  def cta_url_missing_static?(payload)
    return false unless payload['type'] == 'cta_url'

    url = payload.dig('action', 'parameters', 'url').to_s
    url.blank? || url == Whatsapp::InteractiveTemplatePayloadBuilder::DEFAULT_URL_PLACEHOLDER
  end

  def message_attributes(payload)
    base = {
      account: @conversation.account,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      sender: @user
    }

    if payload['type'] == 'rich_text'
      base.merge(
        content: rich_text_content(payload),
        content_type: :text
      )
    else
      base.merge(
        content: @template.body_text.to_s.strip,
        content_type: :integrations,
        content_attributes: { interactive: payload }
      )
    end
  end

  def rich_text_content(payload)
    parts = []
    parts << payload.dig('header', 'text') if payload.dig('header', 'type') == 'text'
    parts << payload.dig('body', 'text')
    parts << "_#{payload.dig('footer', 'text')}_" if payload.dig('footer', 'text').present?
    parts.compact.reject(&:blank?).join("\n\n")
  end

  def whatsapp_conversation?
    @conversation.inbox.channel_type == 'Channel::Whatsapp'
  end
end
