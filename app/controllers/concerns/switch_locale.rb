module SwitchLocale
  extend ActiveSupport::Concern

  private

  def switch_locale(&action)
    # priority is for locale set in query string (mostly for widget/from js sdk)
    locale ||= locale_from_params
    # if locale is not set in account, let's use DEFAULT_LOCALE env variable
    locale ||= locale_from_env_variable
    set_locale(locale, &action)
  end

  def switch_locale_using_account_locale(&action)
    locale = locale_from_account(@current_account)
    set_locale(locale, &action)
  end

  def set_locale(locale, &action)
    # if locale is empty, use default_locale
    locale ||= I18n.default_locale
    # Ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(locale, &action)
  end

  def locale_from_params
    I18n.available_locales.map(&:to_s).include?(params[:locale]) ? params[:locale] : nil
  end

  def locale_from_account(account)
    return unless account

    I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil
  end

  def locale_from_env_variable
    return unless ENV.fetch('DEFAULT_LOCALE', nil)

    I18n.available_locales.map(&:to_s).include?(ENV.fetch('DEFAULT_LOCALE')) ? ENV.fetch('DEFAULT_LOCALE') : nil
  end
end
