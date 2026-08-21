class Whatsapp::AuthenticationTemplateGuard
  pattr_initialize [:channel!, :recipient!, :template_params!]

  def error
    return unless bsuid_recipient?
    return unless authentication_template?

    I18n.t('errors.whatsapp.authentication_template_requires_phone')
  end

  private

  def bsuid_recipient?
    recipient.to_s.delete_prefix('whatsapp:').match?(RegexHelper::WHATSAPP_BSUID_REGEX)
  end

  def authentication_template?
    template&.dig('category')&.casecmp?('authentication')
  end

  def template
    templates.find do |item|
      template_name(item) == param('name') && item['language']&.casecmp?(param('language').to_s)
    end
  end

  def templates
    return Array(channel.message_templates) if channel.is_a?(Channel::Whatsapp)
    return Array(channel.content_templates&.dig('templates')) if channel.is_a?(Channel::TwilioSms)

    []
  end

  def template_name(item)
    channel.is_a?(Channel::TwilioSms) ? item['friendly_name'] : item['name']
  end

  def param(key)
    template_params[key] || template_params[key.to_sym]
  end
end
