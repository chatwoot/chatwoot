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

  # Check if Vite dev server should be used
  # Returns false when using tunnel with built assets (VITE_RUBY_SKIP_DEV_SERVER=true)
  def vite_dev_server_enabled?
    ENV['VITE_RUBY_SKIP_DEV_SERVER'] != 'true'
  end
end
