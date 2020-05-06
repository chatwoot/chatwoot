module ApplicationHelper
  def available_locales_with_name
    enabled_languages = LANGUAGES_CONFIG.filter { |_key, val| val[:enabled] }
    enabled_languages.map { |_key, val| val.slice(:name, :iso_639_1_code) }
  end
end
