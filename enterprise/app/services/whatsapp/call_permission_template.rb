# The WhatsApp template a call permission request goes out as when the contact hasn't messaged in the
# last 24 hours, since Meta delivers the free-form request only inside that window. Chatwoot creates it
# at Meta from the inbox's permission request message, in the account's language. Its name follows its
# language and text, so a changed message is a new template and Meta has to approve it again.
class Whatsapp::CallPermissionTemplate
  NAME_PREFIX = 'chatwoot_call_permission'.freeze
  # Account locales Meta lists under another template language code
  META_LANGUAGE_CODES = { 'no' => 'nb', 'pt' => 'pt_PT' }.freeze
  # Account locales Meta has no template language for; their templates are created in English
  UNSUPPORTED_LOCALES = %w[is].freeze
  DEFAULT_LANGUAGE = 'en'.freeze

  pattr_initialize :channel

  def name
    "#{NAME_PREFIX}_#{Digest::SHA256.hexdigest("#{language}:#{body}").first(12)}"
  end

  def language
    locale = channel.account.locale
    return DEFAULT_LANGUAGE if UNSUPPORTED_LOCALES.include?(locale)

    META_LANGUAGE_CODES.fetch(locale, locale)
  end

  def body
    custom_body.presence || I18n.t('conversations.messages.whatsapp.call_permission_request_body', locale: default_body_locale)
  end

  def created?
    channel.provider_config['call_permission_template_name'] == name
  end

  # Meta reviews the template after this; a send before it approves fails like any unapproved template
  def create!
    return if created?
    return unless channel.provider_service.create_call_permission_template(name: name, language: language, body: body)

    channel.provider_config = channel.provider_config.merge('call_permission_template_name' => name)
    channel.save!(validate: false)
  end

  private

  def custom_body
    channel.provider_config['call_permission_request_body']
  end

  def default_body_locale
    language == DEFAULT_LANGUAGE ? DEFAULT_LANGUAGE : channel.account.locale
  end
end
