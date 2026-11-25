class Whatsapp::AuthenticationTemplateGuard
  pattr_initialize [:channel!, :recipient!, :template_params!]

  def error
    return unless bsuid_recipient?
    return I18n.t('errors.whatsapp.template_category_required_for_bsuid') if template.blank?
    return I18n.t('errors.whatsapp.authentication_template_requires_phone') if authentication_template?
  end

  private

  def bsuid_recipient?
    recipient.to_s.delete_prefix('whatsapp:').match?(RegexHelper::WHATSAPP_BSUID_REGEX)
  end

  def authentication_template?
    template['category'].to_s.casecmp?('authentication')
  end

  def template
    Array(channel.message_templates).find do |item|
      item['name'] == param('name') && item['language']&.casecmp?(param('language').to_s)
    end
  end

  def param(key)
    template_params[key] || template_params[key.to_sym]
  end
end
