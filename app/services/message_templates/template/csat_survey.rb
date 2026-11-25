class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def message_content
    return csat_config['message'] if csat_config['message'].present?

    # The fallback is translated here and stored in `content`, so whatever locale is current
    # when this runs is the locale the customer reads forever. This runs inside the job that
    # resolves the conversation, where I18n.locale is the process default (:en) rather than
    # the account's -- so without this the survey goes out in English to accounts configured
    # in another language, and the wrong text is frozen in the column.
    I18n.with_locale(account_locale) { I18n.t('conversations.templates.csat_input_message_body') }
  end

  # I18n.with_locale raises InvalidLocale on a locale the installation never loaded, and a
  # raise here would take down the resolution that triggered the survey. Same guard, and the
  # same reason, as ApplicationMailer#locale_from_account.
  def account_locale
    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : I18n.default_locale
  end

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: message_content,
      content_attributes: content_attributes
    }
  end

  def csat_config
    inbox.csat_config || {}
  end

  def content_attributes
    {
      display_type: csat_config['display_type'] || 'emoji'
    }
  end
end
