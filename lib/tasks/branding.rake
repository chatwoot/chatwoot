# NOTE: See CUSTOM_BRANDING.md for more details.
require 'fileutils'
require 'net/http'
require 'uri'

namespace :branding do
  desc 'Updates branding configurations from environment variables or defaults'
  task update: :environment do
    image_configs = {
      'LOGO_THUMBNAIL' => 'logo_thumbnail',
      'LOGO' => 'logo',
      'LOGO_DARK' => 'logo_dark',
      'FAVICON' => 'favicon'
    }

    configurable_items = {
      # The installation wide name that would be used in the dashboard, title etc.
      'INSTALLATION_NAME' => 'Chatwoot',
      # The thumbnail that would be used for favicon (512px X 512px)
      'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg',
      # The logo that would be used on the dashboard, login page etc.
      'LOGO' => '/brand-assets/logo.svg',
      # The logo that would be used on the dashboard, login page etc. for dark mode
      'LOGO_DARK' => '/brand-assets/logo_dark.svg',
      # The favicon used across the app
      'FAVICON' => '/brand-assets/favicon.png',
      # The URL that would be used in emails under the section “Powered By”
      'BRAND_URL' => 'https://www.chatwoot.com',
      # The URL that would be used in the widget under the section “Powered By”
      'WIDGET_BRAND_URL' => 'https://www.chatwoot.com',
      # The name that would be used in emails and the widget
      'BRAND_NAME' => 'Chatwoot',
      # Primary brand color used to generate the dashboard palette
      'BRAND_COLOR' => '#1f93ff',
      # The terms of service URL displayed in Signup Page
      'TERMS_URL' => 'https://www.chatwoot.com/terms-of-service',
      # The privacy policy URL displayed in the app
      'PRIVACY_URL' => 'https://www.chatwoot.com/privacy-policy',
      # Display default Chatwoot metadata like favicons and upgrade warnings
      'DISPLAY_MANIFEST' => true
    }

    configurable_items.each do |config_name, default_value|
      value = if default_value.in?([true, false])
                ENV.fetch(config_name, default_value.to_s) == 'true'
              else
                ENV.fetch(config_name, default_value)
              end

      if image_configs.key?(config_name)
        downloaded = download_remote_asset(value, image_configs[config_name], config_name)
        value = downloaded if downloaded
      end

      config = InstallationConfig.find_or_initialize_by(name: config_name)
      config.update!(value: value, locked: config.locked.nil? ? false : config.locked)
      puts "Updated '#{config_name}' to '#{value}'."
    end

    GlobalConfig.clear_cache
    puts 'Branding configuration update finished.'
  end

  def download_remote_asset(value, filename_prefix, config_name)
    return if value.blank?

    uri = safe_uri(value)
    return unless uri

    response = fetch_remote_asset(uri)
    return unless response

    extension = resolve_extension(uri, response['content-type'])
    filename = "#{filename_prefix}#{extension}"
    target_dir = Rails.root.join('public', 'brand-assets')
    FileUtils.mkdir_p(target_dir)
    file_path = target_dir.join(filename)
    File.binwrite(file_path, response.body)

    if config_name == 'FAVICON'
      copy_favicon_assets(file_path, extension)
    end
    if config_name == 'LOGO_THUMBNAIL'
      copy_favicon_assets(file_path, extension)
    end

    "/brand-assets/#{filename}"
  end

  def safe_uri(value)
    uri = URI.parse(value)
    return uri if uri.is_a?(URI::HTTP) && uri.host.present?

    nil
  rescue URI::InvalidURIError
    nil
  end

  def fetch_remote_asset(uri, limit = 3)
    return if limit <= 0

    response = Net::HTTP.get_response(uri)
    return response if response.is_a?(Net::HTTPSuccess)

    if response.is_a?(Net::HTTPRedirection) && response['location'].present?
      next_uri = URI.parse(response['location'])
      return fetch_remote_asset(next_uri, limit - 1)
    end

    nil
  end

  def resolve_extension(uri, content_type)
    extension = extension_from_content_type(content_type)
    return extension if extension

    extension = File.extname(uri.path)
    return extension if extension.present?

    '.png'
  end

  def extension_from_content_type(content_type)
    return if content_type.blank?

    normalized = content_type.split(';').first.to_s.strip.downcase
    return '.png' if normalized == 'image/png'
    return '.jpg' if normalized == 'image/jpeg'
    return '.jpeg' if normalized == 'image/jpg'
    return '.svg' if normalized == 'image/svg+xml'
    return '.webp' if normalized == 'image/webp'
    return '.ico' if normalized == 'image/x-icon'

    nil
  end

  def copy_favicon_assets(source_path, extension)
    return unless extension == '.png'

    favicon_files = %w[
      favicon-16x16.png
      favicon-32x32.png
      favicon-96x96.png
      favicon-512x512.png
      apple-touch-icon.png
      apple-touch-icon-precomposed.png
    ]

    favicon_files.each do |filename|
      FileUtils.cp(source_path, Rails.root.join('public', filename))
    end
  end
end
