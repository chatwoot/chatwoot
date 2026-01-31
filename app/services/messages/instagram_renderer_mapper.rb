# frozen_string_literal: true

module Messages
  class InstagramRendererMapper
    # Maps Instagram rich message payload to Chatwoot message format
    # @param payload [Hash] The Instagram rich message payload
    # @return [OpenStruct] Contains content_type, content_attributes, and fallback_text
    def self.map(payload)
      Rails.logger.info "[INSTAGRAM-MAPPER] Mapping payload: #{payload.inspect}"

      template_type = payload['template_type']

      case template_type
      when 'generic'
        map_generic_template(payload)
      when 'button'
        map_button_template(payload)
      else
        # Quick replies or unknown type
        map_quick_replies(payload)
      end
    end

    class << self
      private

      # Map Generic Template to Chatwoot cards format
      def map_generic_template(payload)
        Rails.logger.info "[INSTAGRAM-MAPPER] Mapping generic template"

        elements = payload['elements'] || []
        items = elements.map do |element|
          item = {
            'title' => element['title'] || '',
            'description' => element['subtitle'] || ''
          }
          item['media_url'] = element['image_url'] if element['image_url'].present?

          if element['buttons'].present?
            item['actions'] = element['buttons'].map do |button|
              action = {
                'text' => button['title'],
                'type' => button['type']
              }
              action['payload'] = button['payload'] if button['payload'].present?
              action['url'] = button['url'] if button['url'].present?
              action
            end
          end

          item
        end

        fallback_text = elements.map { |e| e['title'] }.compact.join(' | ')

        OpenStruct.new(
          content_type: 'cards',
          content_attributes: { 'items' => items },
          fallback_text: fallback_text.presence || 'Rich message'
        )
      end

      # Map Button Template to Chatwoot input_select or cards format
      def map_button_template(payload)
        Rails.logger.info "[INSTAGRAM-MAPPER] Mapping button template"

        text = payload['text'] || ''
        buttons = payload['buttons'] || []

        actions = buttons.map do |button|
          action = {
            'text' => button['title'],
            'type' => button['type']
          }
          action['payload'] = button['payload'] if button['payload'].present?
          action['url'] = button['url'] if button['url'].present?
          action
        end

        # Use cards format with a single item containing buttons
        items = [
          {
            'title' => text,
            'description' => '',
            'actions' => actions
          }
        ]

        OpenStruct.new(
          content_type: 'cards',
          content_attributes: { 'items' => items },
          fallback_text: text.presence || 'Button message'
        )
      end

      # Map Quick Replies to Chatwoot input_select format
      def map_quick_replies(payload)
        Rails.logger.info "[INSTAGRAM-MAPPER] Mapping quick replies"

        text = payload['text'] || ''
        quick_replies = payload['quick_replies'] || []

        if quick_replies.any?
          options = quick_replies.map do |qr|
            {
              'title' => qr['title'],
              'value' => qr['payload'] || qr['title']
            }
          end

          # Use cards format with a single item for quick replies
          items = [
            {
              'title' => text,
              'description' => '',
              'actions' => quick_replies.map do |qr|
                {
                  'text' => qr['title'],
                  'type' => 'postback',
                  'payload' => qr['payload'] || qr['title']
                }
              end
            }
          ]

          OpenStruct.new(
            content_type: 'cards',
            content_attributes: { 'items' => items },
            fallback_text: text.presence || 'Quick reply message'
          )
        else
          # Plain text message
          OpenStruct.new(
            content_type: 'text',
            content_attributes: {},
            fallback_text: text.presence || ''
          )
        end
      end
    end
  end
end
