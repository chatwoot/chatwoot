module ApplicationHelper
  def available_locales
    Rails.configuration.i18n.available_locales
  end
end
