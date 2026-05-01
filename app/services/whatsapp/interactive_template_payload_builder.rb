# frozen_string_literal: true

class Whatsapp::InteractiveTemplatePayloadBuilder
  class ValidationError < StandardError; end

  BODY_MAX = 1024
  FOOTER_MAX = 60
  HEADER_MAX = 60
  BUTTON_TEXT_MAX = 20
  QUICK_REPLY_MAX = 20
  MAX_QUICK_REPLIES_WITH_CTA = 2
  MAX_QUICK_REPLIES_STANDALONE = 3
  DEFAULT_URL_PLACEHOLDER = '__CTA_URL__'

  def initialize(template: nil, template_attributes: nil, runtime_url: nil, runtime_body_text: nil)
    @template = template
    @template_attributes = template_attributes&.with_indifferent_access || {}
    @runtime_url = runtime_url
    @runtime_body_text = runtime_body_text
  end

  def build_template_payload
    attrs = normalized_attributes
    validate!(attrs)

    case attrs[:template_type]
    when 'rich_text'        then build_rich_text_template_payload(attrs)
    when 'quick_replies'    then build_quick_replies_template_payload(attrs)
    else                         build_cta_template_payload(attrs)
    end
  end

  def build
    payload = (@template&.payload || build_template_payload).deep_dup.with_indifferent_access

    case payload[:type]
    when 'rich_text'    then build_rich_text_runtime(payload)
    when 'button'       then build_quick_replies_runtime(payload)
    else                     build_cta_url_runtime(payload)
    end
  end

  private

  def normalized_attributes
    return @template_attributes if @template_attributes.present?

    {
      template_type: @template.template_type,
      header_type: @template.header_type,
      header_text: @template.header_text,
      header_image_url: @template.header_image_url,
      body_text: @template.body_text,
      footer_text: @template.footer_text,
      button_text: @template.button_text,
      url_placeholder: @template.url_placeholder,
      static_url: @template.static_url,
      quick_replies: @template.quick_replies
    }.with_indifferent_access
  end

  def apply_runtime_body_text!(payload)
    body_text = @runtime_body_text.to_s.strip
    raise ValidationError, 'Body text is required' if body_text.blank?
    raise ValidationError, "Body text must be under #{BODY_MAX} characters" if body_text.length > BODY_MAX

    payload[:body] = { text: body_text }
  end

  def validate!(attrs)
    validate_template_type!(attrs)
    validate_body!(attrs)
    validate_footer!(attrs)
    validate_button!(attrs) if attrs[:template_type] == 'cta_url'
    validate_static_url!(attrs) if attrs[:template_type] == 'cta_url'
    validate_quick_replies!(attrs)
    validate_header!(attrs)
  end

  def build_cta_template_payload(attrs)
    payload = {
      'type' => 'cta_url',
      'body' => { 'text' => attrs[:body_text].strip },
      'action' => {
        'name' => 'cta_url',
        'parameters' => {
          'display_text' => attrs[:button_text].strip,
          'url' => effective_cta_url(attrs)
        }
      }
    }

    payload['quick_replies'] = quick_reply_entries(attrs) if quick_reply_entries(attrs).any?
    decorate_with_header_and_footer!(payload, attrs)
    payload
  end

  def build_rich_text_template_payload(attrs)
    payload = {
      'type' => 'rich_text',
      'body' => { 'text' => attrs[:body_text].strip }
    }
    decorate_with_header_and_footer!(payload, attrs)
    payload
  end

  def build_quick_replies_template_payload(attrs)
    entries = quick_reply_entries(attrs)
    raise ValidationError, 'At least one quick reply is required' if entries.empty?

    payload = {
      'type' => 'button',
      'body' => { 'text' => attrs[:body_text].strip },
      'action' => {
        'buttons' => entries.each_with_index.map do |reply, idx|
          {
            'type' => 'reply',
            'reply' => { 'id' => reply['id'] || "qr_#{idx + 1}", 'title' => reply['text'] }
          }
        end
      }
    }
    decorate_with_header_and_footer!(payload, attrs)
    payload
  end

  def decorate_with_header_and_footer!(payload, attrs)
    header_payload = build_header_payload(attrs)
    payload['header'] = header_payload if header_payload.present?
    payload['footer'] = { 'text' => attrs[:footer_text].strip } if attrs[:footer_text].present?
  end

  def build_header_payload(attrs)
    case attrs[:header_type]
    when 'text'
      { 'type' => 'text', 'text' => attrs[:header_text].strip }
    when 'image'
      { 'type' => 'image', 'image' => { 'link' => attrs[:header_image_url].strip } }
    end
  end

  def effective_cta_url(attrs)
    static = attrs[:static_url].to_s.strip
    return static if static.present?

    attrs[:url_placeholder].presence || DEFAULT_URL_PLACEHOLDER
  end

  def quick_reply_entries(attrs)
    Array(attrs[:quick_replies]).map { |qr| qr.respond_to?(:with_indifferent_access) ? qr.with_indifferent_access : qr }
                                .select { |qr| qr['text'].to_s.strip.present? }
                                .map { |qr| { 'id' => qr['id'].to_s.presence, 'text' => qr['text'].to_s.strip } }
  end

  def build_cta_url_runtime(payload)
    runtime_url = @runtime_url.presence || payload.dig(:action, :parameters, :url)
    raise ValidationError, 'CTA URL is required' if runtime_url.blank?

    payload[:action][:parameters][:url] = runtime_url
    apply_runtime_body_text!(payload) if @runtime_body_text.present?
    payload.deep_stringify_keys
  end

  def build_rich_text_runtime(payload)
    body_text = @runtime_body_text.presence || payload.dig(:body, :text).to_s
    raise ValidationError, 'Body text is required' if body_text.blank?

    payload[:body] = { text: body_text }
    payload.deep_stringify_keys
  end

  def build_quick_replies_runtime(payload)
    apply_runtime_body_text!(payload) if @runtime_body_text.present?
    payload.deep_stringify_keys
  end

  def validate_template_type!(attrs)
    return if WhatsappInteractiveTemplate::TEMPLATE_TYPES.include?(attrs[:template_type])

    raise ValidationError, "Template type must be one of: #{WhatsappInteractiveTemplate::TEMPLATE_TYPES.join(', ')}"
  end

  def validate_body!(attrs)
    raise ValidationError, 'Body text is required' if attrs[:body_text].blank?
    return unless attrs[:body_text].to_s.length > BODY_MAX

    raise ValidationError, "Body text must be under #{BODY_MAX} characters"
  end

  def validate_footer!(attrs)
    return unless attrs[:footer_text].to_s.length > FOOTER_MAX

    raise ValidationError, "Footer text must be under #{FOOTER_MAX} characters"
  end

  def validate_button!(attrs)
    raise ValidationError, 'Button text is required' if attrs[:button_text].blank?
    return unless attrs[:button_text].to_s.length > BUTTON_TEXT_MAX

    raise ValidationError, "Button text must be under #{BUTTON_TEXT_MAX} characters"
  end

  def validate_static_url!(attrs)
    static = attrs[:static_url].to_s.strip
    return if static.blank?

    uri = URI.parse(static)
    raise ValidationError, 'Static URL must use http or https' unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    raise ValidationError, 'Static URL is invalid'
  end

  def validate_quick_replies!(attrs)
    entries = quick_reply_entries(attrs)
    return if entries.empty?

    max = attrs[:template_type] == 'cta_url' ? MAX_QUICK_REPLIES_WITH_CTA : MAX_QUICK_REPLIES_STANDALONE
    raise ValidationError, "Maximum #{max} quick replies allowed" if entries.size > max

    invalid = entries.find { |qr| qr['text'].length > QUICK_REPLY_MAX }
    return unless invalid

    raise ValidationError, "Quick reply text must be under #{QUICK_REPLY_MAX} characters"
  end

  def validate_header!(attrs)
    case attrs[:header_type]
    when 'none' then nil
    when 'text' then validate_text_header!(attrs)
    when 'image' then validate_image_header!(attrs)
    else raise ValidationError, 'Header type is invalid'
    end
  end

  def validate_text_header!(attrs)
    raise ValidationError, 'Header text is required' if attrs[:header_text].blank?
    return unless attrs[:header_text].to_s.length > HEADER_MAX

    raise ValidationError, "Header text must be under #{HEADER_MAX} characters"
  end

  def validate_image_header!(attrs)
    return if attrs[:header_image_url].present?

    raise ValidationError, 'Header image URL is required'
  end
end
