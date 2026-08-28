class Captain::Tools::Admin::UpdateAccountSettingsService < Captain::Tools::Admin::BaseTool
  ALLOWED_SETTINGS = %w[
    auto_resolve_after auto_resolve_message auto_resolve_ignore_waiting
    audio_transcriptions auto_resolve_label
  ].freeze

  def self.name
    'update_account_settings'
  end

  description 'Update account settings. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :name, type: :string, desc: 'Account name'
  param :locale, type: :string, desc: 'Account locale (e.g. en, fr)'
  param :domain, type: :string, desc: 'Account domain'
  param :support_email, type: :string, desc: 'Support email address'
  param :auto_resolve_after, type: :integer, desc: 'Minutes after which conversations auto-resolve'
  param :auto_resolve_message, type: :string, desc: 'Message sent when a conversation auto-resolves'
  param :auto_resolve_ignore_waiting, type: :boolean, desc: 'Whether to ignore waiting state for auto-resolve'
  param :audio_transcriptions, type: :boolean, desc: 'Enable audio transcriptions'
  param :auto_resolve_label, type: :string, desc: 'Label applied when a conversation auto-resolves'

  def execute(confirmed:, name: nil, locale: nil, domain: nil, support_email: nil, **settings)
    confirmation_error = require_confirmation!(confirmed, name: name, locale: locale, domain: domain, support_email: support_email, **settings)
    return confirmation_error if confirmation_error.present?

    account_record = account
    apply_account_attributes(account_record, name: name, locale: locale, domain: domain, support_email: support_email)
    settings_applied = apply_settings(account_record, settings)

    return 'No changes were provided' unless account_record.changed? || settings_applied

    account_record.save!
    "Account settings updated successfully.\n#{format_account_summary(account_record)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update account settings: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def apply_account_attributes(account_record, name:, locale:, domain:, support_email:)
    account_record.name = name unless name.nil?
    account_record.locale = locale unless locale.nil?
    account_record.domain = domain unless domain.nil?
    account_record.support_email = support_email unless support_email.nil?
  end

  def apply_settings(account_record, settings)
    applied = false
    settings.each do |key, value|
      next unless ALLOWED_SETTINGS.include?(key.to_s)
      next if value.nil?

      account_record.public_send("#{key}=", value)
      applied = true
    end
    applied
  end

  def format_account_summary(account_record)
    <<~TEXT.strip
      Name: #{account_record.name}
      Locale: #{account_record.locale}
      Domain: #{account_record.domain}
      Support email: #{account_record.support_email}
      Settings: #{account_record.settings.to_json}
    TEXT
  end
end
