class ContentAttributeValidator < ActiveModel::Validator # rubocop:disable Metrics/ClassLength
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_PROVIDER_ERROR_KEYS = [:external_error].freeze
  ALLOWED_CTA_URL_KEYS = [:body_text, :footer_text, :header, :action].concat(ALLOWED_PROVIDER_ERROR_KEYS).freeze
  ALLOWED_CTA_URL_HEADER_KEYS = [:type, :media_url].freeze
  ALLOWED_CTA_URL_ACTION_KEYS = [:text, :uri].freeze
  ALLOWED_INTERACTIVE_BUTTONS_KEYS = [:header, :body_text, :footer_text, :buttons].concat(ALLOWED_PROVIDER_ERROR_KEYS).freeze
  ALLOWED_INTERACTIVE_BUTTONS_HEADER_KEYS = [:type, :media_url].freeze
  ALLOWED_INTERACTIVE_BUTTONS_BUTTON_KEYS = [:id, :text, :type, :uri].freeze
  ALLOWED_INTERACTIVE_LIST_KEYS = [:header, :body_text, :footer_text, :action, :sections].concat(ALLOWED_PROVIDER_ERROR_KEYS).freeze
  ALLOWED_INTERACTIVE_LIST_HEADER_KEYS = [:type, :text].freeze
  ALLOWED_INTERACTIVE_LIST_ACTION_KEYS = [:button_text].freeze
  ALLOWED_INTERACTIVE_LIST_SECTION_KEYS = [:title, :rows].freeze
  ALLOWED_INTERACTIVE_LIST_ROW_KEYS = [:id, :title, :description].freeze
  # WhatsApp caps the combined row count across all sections at 10, not per section.
  MAX_INTERACTIVE_LIST_TOTAL_ROWS = 10
  URL_ACTION_TYPE = 'url'.freeze
  REPLY_ACTION_TYPE = 'reply'.freeze
  CTA_URL_HEADER_TYPE = 'image'.freeze
  INTERACTIVE_BUTTONS_HEADER_TYPE = 'image'.freeze
  INTERACTIVE_LIST_HEADER_TYPE = 'text'.freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze
  SUPPORTED_CARD_ACTION_TYPES = [URL_ACTION_TYPE, REPLY_ACTION_TYPE, 'link', 'postback'].freeze

  VALIDATIONS_BY_CONTENT_TYPE = {
    'input_select' => :validate_input_select!,
    'cards' => :validate_cards!,
    'cta_url' => :validate_cta_url_attributes!,
    'interactive_buttons' => :validate_interactive_buttons_attributes!,
    'interactive_list' => :validate_interactive_list_attributes!,
    'form' => :validate_form!,
    'article' => :validate_article!
  }.freeze

  def validate(record)
    validation = VALIDATIONS_BY_CONTENT_TYPE[record.content_type]
    send(validation, record) if validation
  end

  private

  def validate_input_select!(record)
    validate_items!(record)
    validate_item_attributes!(record, ALLOWED_SELECT_ITEM_KEYS)
  end

  def validate_cards!(record)
    validate_items!(record)
    validate_item_attributes!(record, ALLOWED_CARD_ITEM_KEYS)
    validate_card_titles!(record)
    validate_item_actions!(record)
    validate_interactive_card_actions!(record)
    validate_whatsapp_carousel_action_type_consistency!(record)
  end

  # validate_whatsapp_interactive_card_actions! only rejects mixed action types
  # within a single card. WhatsApp requires the button type/count to match
  # across every card in the carousel, so also check across cards here.
  def validate_whatsapp_carousel_action_type_consistency!(record)
    return unless whatsapp_interactive_carousel_target?(record)

    card_action_types = normalized_items(record).filter_map { |item| item[:actions].pluck(:type).compact.first }.uniq
    return if card_action_types.size <= 1

    record.errors.add(:content_attributes, 'contains carousel cards with mixed action types across cards')
  end

  # Meta requires every generic-template element to have a title; without this
  # check a card with valid actions but a blank title passes here and is only
  # rejected by Facebook/Instagram once it's already been accepted by Chatwoot.
  # Non-Meta cards (e.g. agent bot/API cards sent to website/API inboxes) have
  # no such requirement, so only enforce this for an actual Meta template target.
  def validate_card_titles!(record)
    return unless meta_generic_template_target?(record)
    return if normalized_items(record).none? { |item| item[:title].blank? }

    record.errors.add(:content_attributes, 'contains items missing title')
  end

  def meta_generic_template_target?(record)
    whatsapp_interactive_carousel_target?(record) ||
      instagram_generic_template_target?(record) ||
      messenger_generic_template_target?(record)
  end

  def validate_form!(record)
    validate_items!(record)
    validate_item_attributes!(record, ALLOWED_FORM_ITEM_KEYS)
  end

  def validate_article!(record)
    validate_items!(record)
    validate_item_attributes!(record, ALLOWED_ARTICLE_KEYS)
  end

  def validate_items!(record)
    if record.items.blank?
      record.errors.add(:content_attributes, 'At least one item is required.')
    elsif record.items.reject { |item| item.is_a?(Hash) }.present?
      record.errors.add(:content_attributes, 'Items should be a hash.')
    end
  end

  def validate_item_attributes!(record, valid_keys)
    item_keys = Array(record.items).select { |item| item.is_a?(Hash) }.flat_map(&:keys).filter_map(&:to_sym)
    invalid_keys = item_keys - valid_keys
    record.errors.add(:content_attributes, "contains invalid keys for items : #{invalid_keys}") if invalid_keys.present?
  end

  def validate_item_actions!(record)
    if normalized_items(record).select { |item| item[:actions].blank? }.present?
      record.errors.add(:content_attributes, 'contains items missing actions') && return
    end

    validate_item_action_attributes!(record)
  end

  def validate_item_action_attributes!(record)
    item_action_keys = normalized_items(record).collect { |item| item[:actions].collect(&:keys) }
    invalid_keys = item_action_keys.flatten.compact.map(&:to_sym) - ALLOWED_CARD_ITEM_ACTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for actions:  #{invalid_keys}") if invalid_keys.present?
  end

  def validate_interactive_card_actions!(record)
    normalized_items(record).each { |item| validate_interactive_card_item!(record, item) }
  end

  def validate_interactive_card_item!(record, item)
    return if item[:actions].blank?

    action_types = item[:actions].pluck(:type).compact.uniq
    return if action_types.blank?
    return if reject_unsupported_card_action_types!(record, action_types)

    route_interactive_card_action_validation!(record, item[:actions], action_types)
  end

  def reject_unsupported_card_action_types!(record, action_types)
    unsupported_action_types = action_types - SUPPORTED_CARD_ACTION_TYPES
    return false if unsupported_action_types.blank?

    record.errors.add(:content_attributes, "contains unsupported card action type: #{unsupported_action_types.first}")
    true
  end

  def route_interactive_card_action_validation!(record, actions, action_types)
    if whatsapp_interactive_carousel_target?(record)
      validate_interactive_carousel_item_count!(record)
      validate_whatsapp_interactive_card_actions!(record, actions, action_types)
    elsif instagram_generic_template_target?(record) || messenger_generic_template_target?(record)
      validate_instagram_interactive_card_actions!(record, actions)
    else
      validate_generic_interactive_card_action!(record, actions, action_types.first)
    end
  end

  def validate_generic_interactive_card_action!(record, actions, action_type)
    return unless [URL_ACTION_TYPE, REPLY_ACTION_TYPE].include?(action_type)

    validate_interactive_card_action_shape!(record, actions, action_type)
  end

  def validate_interactive_carousel_item_count!(record)
    return unless whatsapp_interactive_carousel_target?(record)
    return if normalized_items(record).size >= 2

    record.errors.add(:content_attributes, 'interactive carousel messages require at least 2 cards')
  end

  def validate_whatsapp_interactive_card_actions!(record, actions, action_types)
    if action_types.many?
      record.errors.add(:content_attributes, 'contains card actions with mixed action types')
      return
    end

    action_type = action_types.first
    unless [URL_ACTION_TYPE, REPLY_ACTION_TYPE].include?(action_type)
      record.errors.add(:content_attributes, "contains unsupported card action type: #{action_type}")
      return
    end

    validate_interactive_card_action_shape!(record, actions, action_type)
  end

  def validate_instagram_interactive_card_actions!(record, actions)
    record.errors.add(:content_attributes, 'contains card actions missing text') if actions.any? { |action| action[:text].blank? }
    record.errors.add(:content_attributes, 'contains URL actions missing uri') if instagram_url_action_missing_uri?(actions)
    record.errors.add(:content_attributes, 'contains reply actions missing payload') if instagram_reply_action_missing_payload?(actions)
  end

  def instagram_url_action_missing_uri?(actions)
    actions.any? { |action| [URL_ACTION_TYPE, 'link'].include?(action[:type]) && action[:uri].blank? }
  end

  def instagram_reply_action_missing_payload?(actions)
    actions.any? { |action| [REPLY_ACTION_TYPE, 'postback'].include?(action[:type]) && action[:payload].blank? }
  end

  def validate_interactive_card_action_shape!(record, actions, action_type)
    case action_type
    when URL_ACTION_TYPE then validate_carousel_url_actions!(record, actions)
    when REPLY_ACTION_TYPE then validate_carousel_reply_actions!(record, actions)
    end

    record.errors.add(:content_attributes, 'contains card actions missing text') if actions.any? { |action| action[:text].blank? }
  end

  def validate_carousel_url_actions!(record, actions)
    record.errors.add(:content_attributes, 'contains carousel cards with more than one URL action') if actions.size != 1
    record.errors.add(:content_attributes, 'contains carousel URL actions missing uri') if actions.any? { |action| action[:uri].blank? }
  end

  def validate_carousel_reply_actions!(record, actions)
    record.errors.add(:content_attributes, 'contains carousel reply actions missing payload') if actions.any? { |action| action[:payload].blank? }
  end

  def validate_cta_url_attributes!(record)
    content_attributes = ensure_indifferent_access(record.content_attributes)
    invalid_keys = content_attributes.keys.map(&:to_sym) - ALLOWED_CTA_URL_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for cta_url: #{invalid_keys}") if invalid_keys.present?

    record.errors.add(:content_attributes, 'cta_url body_text is required') if content_attributes[:body_text].blank?

    validate_cta_url_header!(record, content_attributes[:header])
    validate_cta_url_action!(record, content_attributes[:action])
  end

  def validate_cta_url_header!(record, header)
    return if header.blank?

    unless header.is_a?(Hash)
      record.errors.add(:content_attributes, 'cta_url header must be a hash')
      return
    end

    header = header.with_indifferent_access
    invalid_keys = header.keys.map(&:to_sym) - ALLOWED_CTA_URL_HEADER_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for cta_url header: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'cta_url header type must be image') if header[:type] != CTA_URL_HEADER_TYPE
    record.errors.add(:content_attributes, 'cta_url header media_url is required') if header[:media_url].blank?
  end

  def validate_cta_url_action!(record, action)
    unless action.is_a?(Hash)
      record.errors.add(:content_attributes, 'cta_url action is required')
      return
    end

    action = action.with_indifferent_access
    invalid_keys = action.keys.map(&:to_sym) - ALLOWED_CTA_URL_ACTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for cta_url action: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'cta_url action text is required') if action[:text].blank?
    record.errors.add(:content_attributes, 'cta_url action uri is required') if action[:uri].blank?
  end

  def validate_interactive_list_attributes!(record)
    content_attributes = ensure_indifferent_access(record.content_attributes)
    invalid_keys = content_attributes.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_LIST_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_list: #{invalid_keys}") if invalid_keys.present?

    record.errors.add(:content_attributes, 'interactive_list body_text is required') if content_attributes[:body_text].blank?

    validate_interactive_list_header!(record, content_attributes[:header])
    validate_interactive_list_action!(record, content_attributes[:action])
    validate_interactive_list_sections!(record, content_attributes[:sections])
  end

  def validate_interactive_buttons_attributes!(record)
    content_attributes = ensure_indifferent_access(record.content_attributes)
    invalid_keys = content_attributes.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_BUTTONS_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_buttons: #{invalid_keys}") if invalid_keys.present?

    record.errors.add(:content_attributes, 'interactive_buttons body_text is required') if content_attributes[:body_text].blank?

    validate_interactive_buttons_header!(record, content_attributes[:header])
    validate_interactive_buttons_buttons!(record, content_attributes[:buttons])
  end

  def validate_interactive_buttons_header!(record, header)
    return if header.blank?

    unless header.is_a?(Hash)
      record.errors.add(:content_attributes, 'interactive_buttons header must be a hash')
      return
    end

    header = header.with_indifferent_access
    invalid_keys = header.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_BUTTONS_HEADER_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_buttons header: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'interactive_buttons header type must be image') if header[:type] != INTERACTIVE_BUTTONS_HEADER_TYPE
    record.errors.add(:content_attributes, 'interactive_buttons header media_url is required') if header[:media_url].blank?
  end

  def validate_interactive_buttons_buttons!(record, buttons)
    unless buttons.is_a?(Array)
      record.errors.add(:content_attributes, 'interactive_buttons buttons must be an array')
      return
    end

    if buttons.blank?
      record.errors.add(:content_attributes, 'interactive_buttons buttons are required')
      return
    end

    if buttons.size > 3
      record.errors.add(:content_attributes, 'interactive_buttons supports at most 3 buttons')
      return
    end

    buttons.each do |button|
      unless button.is_a?(Hash)
        record.errors.add(:content_attributes, 'interactive_buttons buttons must be hashes')
        next
      end

      validate_interactive_buttons_button!(record, button.with_indifferent_access)
    end
  end

  def validate_interactive_buttons_button!(record, button)
    validate_interactive_buttons_button_keys!(record, button)
    record.errors.add(:content_attributes, 'interactive_buttons button text is required') if button[:text].to_s.strip.blank?

    action_type = button[:type].presence || REPLY_ACTION_TYPE
    return if reject_unsupported_button_type!(record, action_type)
    return if reject_non_reply_whatsapp_button!(record, action_type)

    validate_interactive_buttons_button_target!(record, button, action_type)
  end

  def validate_interactive_buttons_button_keys!(record, button)
    invalid_keys = button.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_BUTTONS_BUTTON_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_buttons button: #{invalid_keys}") if invalid_keys.present?
  end

  def reject_unsupported_button_type!(record, action_type)
    return false if [REPLY_ACTION_TYPE, URL_ACTION_TYPE].include?(action_type)

    record.errors.add(:content_attributes, "contains unsupported interactive_buttons button type: #{action_type}")
    true
  end

  def reject_non_reply_whatsapp_button!(record, action_type)
    return false unless whatsapp_interactive_buttons_target?(record) && action_type != REPLY_ACTION_TYPE

    record.errors.add(:content_attributes, 'interactive_buttons only supports reply buttons for WhatsApp')
    true
  end

  def validate_interactive_buttons_button_target!(record, button, action_type)
    if action_type == REPLY_ACTION_TYPE
      record.errors.add(:content_attributes, 'interactive_buttons button id is required') if button[:id].blank?
    elsif button[:uri].blank?
      record.errors.add(:content_attributes, 'interactive_buttons button uri is required')
    end
  end

  def validate_interactive_list_header!(record, header)
    return if header.blank?

    unless header.is_a?(Hash)
      record.errors.add(:content_attributes, 'interactive_list header must be a hash')
      return
    end

    header = header.with_indifferent_access
    invalid_keys = header.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_LIST_HEADER_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_list header: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'interactive_list header type must be text') if header[:type] != INTERACTIVE_LIST_HEADER_TYPE
    record.errors.add(:content_attributes, 'interactive_list header text is required') if header[:text].blank?
  end

  def validate_interactive_list_action!(record, action)
    unless action.is_a?(Hash)
      record.errors.add(:content_attributes, 'interactive_list action is required')
      return
    end

    action = action.with_indifferent_access
    invalid_keys = action.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_LIST_ACTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_list action: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'interactive_list action button_text is required') if action[:button_text].blank?
  end

  def validate_interactive_list_sections!(record, sections)
    unless sections.is_a?(Array)
      record.errors.add(:content_attributes, 'interactive_list sections must be an array')
      return
    end

    if sections.blank?
      record.errors.add(:content_attributes, 'interactive_list sections are required')
      return
    end

    sections.each do |section|
      unless section.is_a?(Hash)
        record.errors.add(:content_attributes, 'interactive_list sections must be hashes')
        next
      end

      validate_interactive_list_section!(record, section.with_indifferent_access)
    end

    validate_interactive_list_total_rows!(record, sections)
  end

  def validate_interactive_list_total_rows!(record, sections)
    total_rows = sections.sum { |section| section.is_a?(Hash) ? Array(section.with_indifferent_access[:rows]).size : 0 }
    return if total_rows <= MAX_INTERACTIVE_LIST_TOTAL_ROWS

    record.errors.add(:content_attributes, "interactive_list supports at most #{MAX_INTERACTIVE_LIST_TOTAL_ROWS} rows across all sections")
  end

  def validate_interactive_list_section!(record, section)
    invalid_keys = section.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_LIST_SECTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_list section: #{invalid_keys}") if invalid_keys.present?

    rows = section[:rows]
    unless rows.is_a?(Array)
      record.errors.add(:content_attributes, 'interactive_list section rows must be an array')
      return
    end

    if rows.blank?
      record.errors.add(:content_attributes, 'interactive_list section rows are required')
      return
    end

    rows.each do |row|
      unless row.is_a?(Hash)
        record.errors.add(:content_attributes, 'interactive_list rows must be hashes')
        next
      end

      validate_interactive_list_row!(record, row.with_indifferent_access)
    end
  end

  def validate_interactive_list_row!(record, row)
    invalid_keys = row.keys.map(&:to_sym) - ALLOWED_INTERACTIVE_LIST_ROW_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for interactive_list row: #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'interactive_list row id is required') if row[:id].blank?
    record.errors.add(:content_attributes, 'interactive_list row title is required') if row[:title].blank?
  end

  def ensure_indifferent_access(value)
    value.is_a?(Hash) ? value.with_indifferent_access : {}
  end

  def normalized_items(record)
    Array(record.items).map do |item|
      item.with_indifferent_access.tap do |normalized_item|
        normalized_item[:actions] = Array(normalized_item[:actions]).map(&:with_indifferent_access)
      end
    end
  end

  def interactive_carousel_message?(record)
    interactive_card_actions_present?(record)
  end

  def whatsapp_interactive_carousel_target?(record)
    record.inbox&.whatsapp? && interactive_card_actions_present?(record)
  end

  def instagram_generic_template_target?(record)
    return false unless interactive_card_actions_present?(record)

    instagram_direct_message_target?(record)
  end

  def messenger_generic_template_target?(record)
    return false unless interactive_card_actions_present?(record)

    record.inbox&.facebook? && record.conversation&.additional_attributes&.dig('type') != 'instagram_direct_message'
  end

  def interactive_card_actions_present?(record)
    normalized_items(record).any? do |item|
      item[:actions].pluck(:type).compact.intersect?([URL_ACTION_TYPE, REPLY_ACTION_TYPE])
    end
  end

  def whatsapp_interactive_buttons_target?(record)
    record.inbox&.whatsapp?
  end

  def instagram_direct_message_target?(record)
    record.inbox&.instagram_direct? ||
      (record.inbox&.facebook? && record.conversation&.additional_attributes&.dig('type') == 'instagram_direct_message')
  end
end
