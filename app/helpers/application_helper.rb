module ApplicationHelper
  def available_locales_with_name
    LANGUAGES_CONFIG.map { |_key, val| val.slice(:name, :iso_639_1_code) }
  end

  def feature_help_urls
    features = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
    features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['help_url'] if feature['help_url']
    end
  end

  def brand_css_variables(global_config)
    primary = hex_to_rgb(global_config['BRAND_PRIMARY_COLOR'], '#2781F6')
    primary_hover = hex_to_rgb(global_config['BRAND_PRIMARY_HOVER_COLOR'], '#1073E9')
    secondary = hex_to_rgb(global_config['BRAND_SECONDARY_COLOR'], '#DAECFF')

    {
      '--brand-color' => primary,
      '--blue-9' => primary,
      '--blue-10' => primary_hover,
      '--blue-11' => primary,
      '--solid-blue' => secondary,
      '--border-blue' => "#{primary.gsub(' ', ', ')}, 0.5"
    }.map { |key, value| "#{key}: #{value}" }.join('; ')
  end

  def brand_theme_color(global_config)
    color = global_config['BRAND_PRIMARY_COLOR'].presence || '#2781F6'
    color.match?(/\A#[0-9a-fA-F]{6}\z/) ? color : '#2781F6'
  end

  private

  def hex_to_rgb(hex, fallback)
    sanitized_hex = hex.presence || fallback
    sanitized_hex = sanitized_hex.to_s.delete_prefix('#')
    fallback_hex = fallback.to_s.delete_prefix('#')
    sanitized_hex = fallback_hex unless sanitized_hex.match?(/\A[0-9a-fA-F]{6}\z/)

    sanitized_hex.scan(/../).map { |component| component.to_i(16) }.join(' ')
  end
end
