# frozen_string_literal: true

module Templates
  class FromAppleMessageService
    attr_reader :account, :message_type, :message_data, :template_params

    def initialize(account, message_type, message_data, template_params = {})
      @account = account
      @message_type = message_type
      @message_data = message_data.is_a?(ActionController::Parameters) ? message_data : message_data.with_indifferent_access
      @template_params = template_params.is_a?(ActionController::Parameters) ? template_params : template_params.with_indifferent_access
    end

    def call
      ActiveRecord::Base.transaction do
        template = create_template
        create_content_block(template)
        create_channel_mapping(template)
        template
      end
    end

    private

    def create_template
      account.message_templates.create!(
        name: template_params[:name] || default_template_name,
        category: template_params[:category] || default_category,
        description: template_params[:description] || default_description,
        status: 'active',
        supported_channels: ['apple_messages_for_business'],
        tags: template_params[:tags] || [],
        parameters: {},
        version: 1
      )
    end

    def create_content_block(template)
      template.content_blocks.create!(
        block_type: block_type_for_message,
        properties: converted_properties,
        order_index: 0
      )
    end

    def create_channel_mapping(template)
      # Store the original message data structure for reference
      # field_mappings should contain mapping paths, not the actual data
      # So we store a simple reference mapping here
      template.channel_mappings.create!(
        channel_type: 'apple_messages_for_business',
        content_type: message_type,
        field_mappings: {}
      )
    end

    def block_type_for_message
      case message_type.to_s
      when 'quick_reply'
        'quick_reply'
      when 'list_picker'
        'list_picker'
      when 'time_picker'
        'time_picker'
      when 'form'
        'form'
      when 'apple_pay'
        'apple_pay'
      else
        'text'
      end
    end

    def converted_properties
      case message_type.to_s
      when 'quick_reply'
        convert_quick_reply_properties
      when 'list_picker'
        convert_list_picker_properties
      when 'time_picker'
        convert_time_picker_properties
      when 'form'
        convert_form_properties
      when 'apple_pay'
        convert_apple_pay_properties
      else
        {}
      end
    end

    def convert_quick_reply_properties
      {
        text: message_data[:text] || message_data[:title],
        subtitle: message_data[:subtitle],
        replies: (message_data[:replies] || []).map do |reply|
          {
            title: reply[:title] || reply['title'],
            value: reply[:value] || reply['value'],
            identifier: reply[:identifier] || reply['identifier']
          }.compact
        end,
        images: message_data[:images] || []
      }.compact
    end

    def convert_list_picker_properties
      {
        title: message_data[:title],
        subtitle: message_data[:subtitle],
        multipleSelection: message_data[:multipleSelection] || message_data[:multiple_selection] || false,
        sections: (message_data[:sections] || []).map do |section|
          {
            title: section[:title] || section['title'],
            multipleSelection: section[:multipleSelection] || section['multipleSelection'] || section[:multiple_selection] || false,
            items: (section[:items] || section['items'] || []).map do |item|
              {
                identifier: item[:identifier] || item['identifier'],
                title: item[:title] || item['title'],
                subtitle: item[:subtitle] || item['subtitle'],
                imageIdentifier: item[:imageIdentifier] || item[:image_identifier] || item['imageIdentifier'],
                style: item[:style] || item['style'] || 'default'
              }.compact
            end
          }.compact
        end,
        images: message_data[:images] || []
      }.compact
    end

    def convert_time_picker_properties
      {
        event: {
          title: message_data.dig(:event, :title) || message_data.dig('event', 'title') || '',
          description: message_data.dig(:event, :description) || message_data.dig('event', 'description'),
          timeslots: message_data.dig(:event, :timeslots) || message_data.dig('event', 'timeslots') || []
        },
        timezoneOffset: message_data[:timezone_offset] || message_data[:timezoneOffset] || message_data['timezoneOffset'],
        receivedMessage: {
          title: message_data[:received_title] || message_data[:receivedTitle] || message_data['receivedTitle'],
          subtitle: message_data[:received_subtitle] || message_data[:receivedSubtitle] || message_data['receivedSubtitle'],
          imageIdentifier: message_data[:received_image_identifier] || message_data[:receivedImageIdentifier] || message_data['receivedImageIdentifier'],
          style: message_data[:received_style] || message_data[:receivedStyle] || message_data['receivedStyle'] || 'icon'
        }.compact,
        replyMessage: {
          title: message_data[:reply_title] || message_data[:replyTitle] || message_data['replyTitle'],
          subtitle: message_data[:reply_subtitle] || message_data[:replySubtitle] || message_data['replySubtitle'],
          imageIdentifier: message_data[:reply_image_identifier] || message_data[:replyImageIdentifier] || message_data['replyImageIdentifier'],
          style: message_data[:reply_style] || message_data[:replyStyle] || message_data['replyStyle'] || 'icon'
        }.compact,
        images: message_data[:images] || []
      }.compact
    end

    def convert_form_properties
      {
        formId: message_data[:form_id] || message_data[:formId] || message_data['formId'],
        title: message_data[:title],
        fields: message_data[:fields] || [],
        receivedMessage: message_data[:received_message] || message_data[:receivedMessage] || {},
        replyMessage: message_data[:reply_message] || message_data[:replyMessage] || {},
        images: message_data[:images] || []
      }.compact
    end

    def convert_apple_pay_properties
      {
        merchantIdentifier: message_data[:merchant_identifier] || message_data[:merchantIdentifier],
        merchantName: message_data[:merchant_name] || message_data[:merchantName],
        lineItems: message_data[:line_items] || message_data[:lineItems] || [],
        total: message_data[:total],
        images: message_data[:images] || []
      }.compact
    end

    def default_template_name
      case message_type.to_s
      when 'quick_reply'
        "Quick Reply - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      when 'list_picker'
        "List Picker - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      when 'time_picker'
        "Time Picker - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      when 'form'
        "Form - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      when 'apple_pay'
        "Apple Pay - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      else
        "Template - #{Time.current.strftime('%Y%m%d%H%M%S')}"
      end
    end

    def default_category
      case message_type.to_s
      when 'time_picker'
        'scheduling'
      when 'apple_pay'
        'payment'
      when 'form'
        'support'
      else
        nil
      end
    end

    def default_description
      case message_type.to_s
      when 'quick_reply'
        'Quick reply message created from Apple Messages conversation'
      when 'list_picker'
        'List picker created from Apple Messages conversation'
      when 'time_picker'
        'Time picker created from Apple Messages conversation'
      when 'form'
        'Form created from Apple Messages conversation'
      when 'apple_pay'
        'Apple Pay request created from Apple Messages conversation'
      else
        'Template created from Apple Messages conversation'
      end
    end
  end
end
