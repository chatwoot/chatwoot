module SwitchLocale
  extend ActiveSupport::Concern

  private

  def switch_locale(&)
    # priority is for locale set in query string (mostly for widget/from js sdk)
    locale ||= params[:locale]

    locale ||= locale_from_custom_domain
    # if locale is not set in account, let's use DEFAULT_LOCALE env variable
    locale ||= ENV.fetch('DEFAULT_LOCALE', nil)
    set_locale(locale, &)
  end

  def switch_locale_using_account_locale(&)
    locale = locale_from_account(@current_account)
    set_locale(locale, &)
  end

  # If the request is coming from a custom domain, it should be for a helpcenter portal
  # We will use the portal locale in such cases
  def locale_from_custom_domain(&)
    return if params[:locale]

    domain = request.host
    return if DomainHelper.chatwoot_domain?(domain)

    @portal = Portal.find_by(custom_domain: domain)
    return unless @portal

    @portal.default_locale
  end

  def set_locale(locale, &)
    safe_locale = validate_and_get_locale(locale)
    # Ensure locale won't bleed into other requests
    # https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
    I18n.with_locale(safe_locale, &)
  end

  def validate_and_get_locale(locale)
    return I18n.default_locale.to_s if locale.blank?

    available_locales = I18n.available_locales.map(&:to_s)
    locale_without_variant = locale.split('_')[0]

    if available_locales.include?(locale)
      locale
    elsif available_locales.include?(locale_without_variant)
      locale_without_variant
    else
      I18n.default_locale.to_s
    end
  end

  def locale_from_account(account)
    return unless account

    account.locale
  end
end
