# rubocop:disable Metrics/ClassLength
class Whatsapp::InteractiveMessages::Registry
  SCHEMA_VERSION = 1
  BUTTON_TYPE = 'button'.freeze
  LIST_TYPE = 'list'.freeze
  BODY_MAX_LENGTH = 1024
  LIST_BODY_MAX_LENGTH = 4096
  HEADER_MAX_LENGTH = 60
  FOOTER_MAX_LENGTH = 60
  HEADER_TYPES = %w[text image video document].freeze
  BUTTON_TITLE_MAX_LENGTH = 20
  BUTTON_COUNT_RANGE = (1..3)
  LIST_BUTTON_MAX_LENGTH = 20
  LIST_SECTION_COUNT_RANGE = (1..10)
  LIST_ROW_COUNT_RANGE = (1..10)
  LIST_SECTION_TITLE_MAX_LENGTH = 24
  LIST_ROW_TITLE_MAX_LENGTH = 24
  LIST_ROW_DESCRIPTION_MAX_LENGTH = 72
  LIST_ROW_DELIVERY_ID_MAX_LENGTH = 200

  IMPLEMENTED_TYPES = [BUTTON_TYPE, LIST_TYPE].freeze

  class << self
    def limits
      button_limits
    end

    def button_limits
      {
        body_max_length: BODY_MAX_LENGTH,
        header_max_length: HEADER_MAX_LENGTH,
        footer_max_length: FOOTER_MAX_LENGTH,
        header_types: HEADER_TYPES,
        button_title_max_length: BUTTON_TITLE_MAX_LENGTH,
        button_min_count: BUTTON_COUNT_RANGE.min,
        button_max_count: BUTTON_COUNT_RANGE.max
      }
    end

    def list_limits
      {
        body_max_length: LIST_BODY_MAX_LENGTH,
        header_max_length: HEADER_MAX_LENGTH,
        footer_max_length: FOOTER_MAX_LENGTH,
        button_max_length: LIST_BUTTON_MAX_LENGTH,
        section_min_count: LIST_SECTION_COUNT_RANGE.min,
        section_max_count: LIST_SECTION_COUNT_RANGE.max,
        row_min_count: LIST_ROW_COUNT_RANGE.min,
        row_max_count: LIST_ROW_COUNT_RANGE.max,
        section_title_max_length: LIST_SECTION_TITLE_MAX_LENGTH,
        row_title_max_length: LIST_ROW_TITLE_MAX_LENGTH,
        row_description_max_length: LIST_ROW_DESCRIPTION_MAX_LENGTH
      }
    end

    def implemented_types
      IMPLEMENTED_TYPES
    end

    def implemented?(type)
      implemented_types.include?(type.to_s)
    end

    def limits_for(type)
      { BUTTON_TYPE => button_limits, LIST_TYPE => list_limits }[type.to_s]
    end

    def resolve(payload)
      path = 'whatsapp_interactive'
      interactive = hash!(payload, path)
      case interactive['type']
      when BUTTON_TYPE then resolve_button_message(interactive, path)
      when LIST_TYPE then resolve_list_message(interactive, path)
      else raise_validation!("#{path}.type must be button or list")
      end
    end

    def provider_payload(snapshot, attachment: nil)
      path = 'stored whatsapp_interactive'
      interactive = hash!(snapshot, path)
      case interactive['type']
      when BUTTON_TYPE then button_provider_payload(interactive, path, attachment)
      when LIST_TYPE then list_provider_payload(interactive, path)
      else raise_validation!("#{path}.type must be button or list")
      end
    end

    def legacy_input_select_payload(message)
      if message.content_attributes['items'].length <= BUTTON_COUNT_RANGE.max
        legacy_button_payload(message)
      else
        legacy_list_payload(message)
      end
    end

    def matching_media?(header_type, attachment)
      return false unless attachment&.file&.attached?

      expected_type = header_type == 'document' ? 'file' : header_type
      return false unless attachment.file_type == expected_type

      content_type = attachment.file.blob.content_type.to_s
      return !content_type.start_with?('image/', 'video/', 'audio/') if header_type == 'document'

      content_type.start_with?("#{header_type}/")
    end

    private

    def resolve_button_message(interactive, path)
      validated_interactive!(interactive, path, BUTTON_TYPE, %w[schema_version type body action], optional: %w[header footer])
      body_text = validated_body_text(interactive, path)
      buttons = validated_buttons(interactive, path)
      value!(BUTTON_COUNT_RANGE.cover?(buttons.length), 'whatsapp_interactive.action.buttons must contain 1 to 3 buttons')

      resolved_buttons = buttons.map.with_index { |button, index| resolve_button(button, index, path) }
      titles = resolved_buttons.pluck('title')
      value!(titles.uniq.length == titles.length, 'whatsapp_interactive button titles must be unique')

      resolved = {
        'schema_version' => SCHEMA_VERSION,
        'type' => BUTTON_TYPE,
        'body' => { 'text' => body_text },
        'action' => { 'buttons' => resolved_buttons }
      }
      resolved['header'] = validated_header(interactive, path) if interactive.key?('header')
      resolved['footer'] = validated_footer(interactive, path) if interactive.key?('footer')
      resolved
    end

    def button_provider_payload(interactive, path, attachment)
      validated_interactive!(interactive, path, BUTTON_TYPE, %w[schema_version type body action], optional: %w[header footer])
      body_text = validated_body_text(interactive, path)
      buttons = validated_buttons(interactive, path)
      value!(BUTTON_COUNT_RANGE.cover?(buttons.length), 'stored whatsapp_interactive.action.buttons must contain 1 to 3 buttons')
      provider_buttons = buttons.map.with_index { |button, index| provider_button(button, index, path) }

      payload = {
        type: BUTTON_TYPE,
        body: { text: body_text },
        action: { buttons: provider_buttons }
      }
      payload[:header] = provider_header(interactive, path, attachment) if interactive.key?('header')
      payload[:footer] = { text: validated_footer(interactive, path)['text'] } if interactive.key?('footer')
      payload
    end

    def resolve_list_message(interactive, path)
      validated_interactive!(interactive, path, LIST_TYPE, %w[schema_version type body action], optional: %w[header footer])
      body_text = validated_list_body_text(interactive, path)
      sections = validated_list_sections(interactive, path)
      resolved = {
        'schema_version' => SCHEMA_VERSION,
        'type' => LIST_TYPE,
        'body' => { 'text' => body_text },
        'action' => {
          'button' => validated_list_button(interactive, path),
          'sections' => sections.map.with_index { |section, index| resolve_list_section(section, index, path) }
        }
      }
      resolved['header'] = validated_list_header(interactive, path) if interactive.key?('header')
      resolved['footer'] = validated_footer(interactive, path) if interactive.key?('footer')
      resolved
    end

    def list_provider_payload(interactive, path)
      validated_interactive!(interactive, path, LIST_TYPE, %w[schema_version type body action], optional: %w[header footer])
      payload = {
        type: LIST_TYPE,
        body: { text: validated_list_body_text(interactive, path) },
        action: {
          button: validated_list_button(interactive, path),
          sections: validated_list_sections(interactive, path).map.with_index { |section, index| provider_list_section(section, index, path) }
        }
      }
      payload[:header] = { type: 'text', text: validated_list_header(interactive, path)['text'] } if interactive.key?('header')
      payload[:footer] = { text: validated_footer(interactive, path)['text'] } if interactive.key?('footer')
      payload
    end

    def validated_interactive!(interactive, path, type, required, optional: [])
      exact_keys!(interactive, required, path, optional: optional)
      value!(interactive['schema_version'] == SCHEMA_VERSION, "#{path}.schema_version must be 1")
      value!(interactive['type'] == type, "#{path}.type must be #{type}")
    end

    def validated_body_text(interactive, path)
      body = hash!(interactive['body'], "#{path}.body")
      exact_keys!(body, %w[text], "#{path}.body")
      text!(body['text'], "#{path}.body.text", BODY_MAX_LENGTH)
    end

    def validated_list_body_text(interactive, path)
      body = hash!(interactive['body'], "#{path}.body")
      exact_keys!(body, %w[text], "#{path}.body")
      text!(body['text'], "#{path}.body.text", LIST_BODY_MAX_LENGTH)
    end

    def validated_list_header(interactive, path)
      header_path = "#{path}.header"
      header = hash!(interactive['header'], header_path)
      exact_keys!(header, %w[type text], header_path)
      value!(header['type'] == 'text', "#{header_path}.type must be text")
      { 'type' => 'text', 'text' => text!(header['text'], "#{header_path}.text", HEADER_MAX_LENGTH) }
    end

    def validated_header(interactive, path, stored: false)
      header_path = "#{path}.header"
      header = hash!(interactive['header'], header_path)
      value!(HEADER_TYPES.include?(header['type']), "#{header_path}.type must be text, image, video, or document")
      if header['type'] == 'text'
        exact_keys!(header, %w[type text], header_path)
        text!(header['text'], "#{header_path}.text", HEADER_MAX_LENGTH)
      else
        exact_keys!(header, stored ? %w[type attachment_id] : %w[type], header_path)
        if stored
          value!(header['attachment_id'].is_a?(Integer) && header['attachment_id'].positive?,
                 "#{header_path}.attachment_id must be a server attachment ID")
        end
      end
      header
    end

    def validated_footer(interactive, path)
      footer = hash!(interactive['footer'], "#{path}.footer")
      exact_keys!(footer, %w[text], "#{path}.footer")
      { 'text' => text!(footer['text'], "#{path}.footer.text", FOOTER_MAX_LENGTH) }
    end

    def provider_header(interactive, path, attachment)
      header = validated_header(interactive, path, stored: true)
      return { type: 'text', text: header['text'] } if header['type'] == 'text'

      value!(attachment && attachment.id == header['attachment_id'] && matching_media?(header['type'], attachment),
             "#{path}.header media is unavailable or mismatched")
      media = { link: attachment.download_url }
      media[:filename] = attachment.file.filename.to_s if header['type'] == 'document'
      { :type => header['type'], header['type'].to_sym => media }
    end

    def validated_buttons(interactive, path)
      action = hash!(interactive['action'], "#{path}.action")
      exact_keys!(action, %w[buttons], "#{path}.action")
      array!(action['buttons'], "#{path}.action.buttons")
    end

    def resolve_button(button, index, path)
      button_path = "#{path}.action.buttons[#{index}]"
      button = hash!(button, button_path)
      exact_keys!(button, %w[title], button_path)
      { 'delivery_id' => "reply_#{SecureRandom.uuid}", 'title' => text!(button['title'], "#{button_path}.title", BUTTON_TITLE_MAX_LENGTH) }
    end

    def provider_button(button, index, path)
      button_path = "#{path}.action.buttons[#{index}]"
      button = hash!(button, button_path)
      exact_keys!(button, %w[delivery_id title], button_path)
      delivery_id = text!(button['delivery_id'], "#{button_path}.delivery_id", 256)
      title = text!(button['title'], "#{button_path}.title", BUTTON_TITLE_MAX_LENGTH)
      { type: 'reply', reply: { id: delivery_id, title: title } }
    end

    def validated_list_button(interactive, path)
      action = hash!(interactive['action'], "#{path}.action")
      exact_keys!(action, %w[button sections], "#{path}.action")
      text!(action['button'], "#{path}.action.button", LIST_BUTTON_MAX_LENGTH)
    end

    def validated_list_sections(interactive, path)
      action = hash!(interactive['action'], "#{path}.action")
      exact_keys!(action, %w[button sections], "#{path}.action")
      sections = array!(action['sections'], "#{path}.action.sections")
      value!(LIST_SECTION_COUNT_RANGE.cover?(sections.length), "#{path}.action.sections must contain 1 to 10 sections")
      total_rows = sections.sum do |section|
        section_hash = hash!(section, "#{path}.action.sections")
        rows = section_hash['rows']
        rows.is_a?(Array) ? rows.length : 0
      end
      value!(LIST_ROW_COUNT_RANGE.cover?(total_rows), "#{path}.action.sections must contain 1 to 10 rows in total")
      sections
    end

    def resolve_list_section(section, index, path)
      section_path = "#{path}.action.sections[#{index}]"
      section = hash!(section, section_path)
      exact_keys!(section, %w[rows], section_path, optional: %w[title])
      rows = array!(section['rows'], "#{section_path}.rows")
      value!(rows.present?, "#{section_path}.rows must contain at least one row")
      resolved = { 'rows' => rows.map.with_index { |row, row_index| resolve_list_row(row, row_index, section_path) } }
      resolved['title'] = text!(section['title'], "#{section_path}.title", LIST_SECTION_TITLE_MAX_LENGTH) if section.key?('title')
      resolved
    end

    def resolve_list_row(row, index, section_path)
      row_path = "#{section_path}.rows[#{index}]"
      row = hash!(row, row_path)
      exact_keys!(row, %w[title], row_path, optional: %w[description])
      resolved = {
        'delivery_id' => "row_#{SecureRandom.uuid}",
        'title' => text!(row['title'], "#{row_path}.title", LIST_ROW_TITLE_MAX_LENGTH)
      }
      resolved['description'] = text!(row['description'], "#{row_path}.description", LIST_ROW_DESCRIPTION_MAX_LENGTH) if row.key?('description')
      resolved
    end

    def provider_list_section(section, index, path)
      section_path = "#{path}.action.sections[#{index}]"
      section = hash!(section, section_path)
      exact_keys!(section, %w[rows], section_path, optional: %w[title])
      rows = array!(section['rows'], "#{section_path}.rows")
      value!(rows.present?, "#{section_path}.rows must contain at least one row")
      provider_section = { rows: rows.map.with_index { |row, row_index| provider_list_row(row, row_index, section_path) } }
      provider_section[:title] = text!(section['title'], "#{section_path}.title", LIST_SECTION_TITLE_MAX_LENGTH) if section.key?('title')
      provider_section
    end

    def provider_list_row(row, index, section_path)
      row_path = "#{section_path}.rows[#{index}]"
      row = hash!(row, row_path)
      exact_keys!(row, %w[delivery_id title], row_path, optional: %w[description])
      provider_row = {
        id: text!(row['delivery_id'], "#{row_path}.delivery_id", LIST_ROW_DELIVERY_ID_MAX_LENGTH),
        title: text!(row['title'], "#{row_path}.title", LIST_ROW_TITLE_MAX_LENGTH)
      }
      provider_row[:description] = text!(row['description'], "#{row_path}.description", LIST_ROW_DESCRIPTION_MAX_LENGTH) if row.key?('description')
      provider_row
    end

    def legacy_button_payload(message)
      buttons = message.content_attributes['items'].map do |item|
        { :type => 'reply', 'reply' => { 'id' => item['value'], 'title' => item['title'] } }
      end
      legacy_payload('button', message.outgoing_content, JSON.generate('buttons' => buttons))
    end

    def legacy_list_payload(message)
      rows = message.content_attributes['items'].map { |item| { 'id' => item['value'], 'title' => item['title'] } }
      action = { 'button' => I18n.t('conversations.messages.whatsapp.list_button_label'), 'sections' => [{ 'rows' => rows }] }
      legacy_payload('list', message.outgoing_content, JSON.generate(action))
    end

    def legacy_payload(type, content, action)
      { type: type, body: { text: content }, action: action }
    end

    def hash!(value, path)
      value!(value.is_a?(Hash) || value.is_a?(ActionController::Parameters), "#{path} must be an object")
      value.to_h.deep_stringify_keys
    end

    def array!(value, path)
      value!(value.is_a?(Array), "#{path} must be an array")
      value
    end

    def exact_keys!(value, expected, path, optional: [])
      keys = value.keys.map(&:to_s)
      unexpected = keys - expected - optional
      missing = expected - keys
      value!(unexpected.empty?, "#{path} contains unsupported fields: #{unexpected.join(', ')}")
      value!(missing.empty?, "#{path} is missing required fields: #{missing.join(', ')}")
    end

    def text!(value, path, maximum)
      value!(value.is_a?(String), "#{path} must be text")
      value!(value.present?, "#{path} cannot be blank")
      value!(value.length <= maximum, "#{path} must be #{maximum} characters or fewer")
      value
    end

    def value!(condition, message)
      raise Whatsapp::InteractiveMessages::ValidationError, message unless condition
    end

    def raise_validation!(message)
      raise Whatsapp::InteractiveMessages::ValidationError, message
    end
  end
end
# rubocop:enable Metrics/ClassLength
