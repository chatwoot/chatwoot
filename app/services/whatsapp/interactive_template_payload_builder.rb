# frozen_string_literal: true

class Whatsapp::InteractiveTemplatePayloadBuilder
  class ValidationError < StandardError; end

  BODY_MAX = 1024
  FOOTER_MAX = 60
  HEADER_MAX = 60
  BUTTON_TEXT_MAX = 20
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

    if attrs[:template_type] == 'rich_text'
      return build_rich_text_template_payload(attrs)
    end

    payload = {
      'type' => 'cta_url',
      'body' => {
        'text' => attrs[:body_text].strip
      },
      'action' => {
        'name' => 'cta_url',
        'parameters' => {
          'display_text' => attrs[:button_text].strip,
          'url' => attrs[:url_placeholder].presence || DEFAULT_URL_PLACEHOLDER
        }
      }
    }

    header_payload = build_header_payload(attrs)
    payload['header'] = header_payload if header_payload.present?
    payload['footer'] = { 'text' => attrs[:footer_text].strip } if attrs[:footer_text].present?
    payload
  end

  def build
    payload = (@template&.payload || build_template_payload).deep_dup.with_indifferent_access

    return build_rich_text_runtime(payload) if payload[:type] == 'rich_text'

    runtime_url = @runtime_url.presence || payload.dig(:action, :parameters, :url)

    raise ValidationError, 'CTA URL is required' if runtime_url.blank?

    payload[:action][:parameters][:url] = runtime_url
    apply_runtime_body_text!(payload) if @runtime_body_text.present?
    payload.deep_stringify_keys
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
      url_placeholder: @template.url_placeholder
    }.with_indifferent_access
  end

  def apply_runtime_body_text!(payload)
    body_text = @runtime_body_text.to_s.strip
    raise ValidationError, 'Body text is required' if body_text.blank?
    raise ValidationError, 'Body text must be under 1024 characters' if body_text.length > BODY_MAX

    payload[:body] = { text: body_text }
  end

  def validate!(attrs)
    validate_template_type!(attrs)
    validate_body!(attrs)
    validate_footer!(attrs)
    validate_button!(attrs) unless attrs[:template_type] == 'rich_text'
    validate_header!(attrs)
  end

  def build_header_payload(attrs)
    case attrs[:header_type]
    when 'text'
      {
        'type' => 'text',
        'text' => attrs[:header_text].strip
      }
    when 'image'
      {
        'type' => 'image',
        'image' => {
          'link' => attrs[:header_image_url].strip
        }
      }
    end
  end

  def build_rich_text_template_payload(attrs)
    payload = {
      'type' => 'rich_text',
      'body' => { 'text' => attrs[:body_text].strip }
    }

    header_payload = build_header_payload(attrs)
    payload['header'] = header_payload if header_payload.present?
    payload['footer'] = { 'text' => attrs[:footer_text].strip } if attrs[:footer_text].present?
    payload
  end

  def build_rich_text_runtime(payload)
    body_text = @runtime_body_text.presence || payload.dig(:body, :text).to_s
    raise ValidationError, 'Body text is required' if body_text.blank?

    payload[:body] = { text: body_text }
    payload.deep_stringify_keys
  end

  def validate_template_type!(attrs)
    return if %w[cta_url rich_text].include?(attrs[:template_type])

    raise ValidationError, 'Template type must be cta_url or rich_text'
  end

  def validate_body!(attrs)
    raise ValidationError, 'Body text is required' if attrs[:body_text].blank?
    return unless attrs[:body_text].to_s.length > BODY_MAX

    raise ValidationError, 'Body text must be under 1024 characters'
  end

  def validate_footer!(attrs)
    return unless attrs[:footer_text].to_s.length > FOOTER_MAX

    raise ValidationError, 'Footer text must be under 60 characters'
  end

  def validate_button!(attrs)
    raise ValidationError, 'Button text is required' if attrs[:button_text].blank?
    return unless attrs[:button_text].to_s.length > BUTTON_TEXT_MAX

    raise ValidationError, 'Button text must be under 20 characters'
  end

  def validate_header!(attrs)
    case attrs[:header_type]
    when 'none'
      nil
    when 'text'
      validate_text_header!(attrs)
    when 'image'
      validate_image_header!(attrs)
    else
      raise ValidationError, 'Header type is invalid'
    end
  end

  def validate_text_header!(attrs)
    raise ValidationError, 'Header text is required' if attrs[:header_text].blank?
    return unless attrs[:header_text].to_s.length > HEADER_MAX

    raise ValidationError, 'Header text must be under 60 characters'
  end

  def validate_image_header!(attrs)
    return if attrs[:header_image_url].present?

    raise ValidationError, 'Header image URL is required'
  end
end
