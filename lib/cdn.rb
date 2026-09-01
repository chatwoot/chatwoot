module Cdn
  module_function

  # Returns `path` prefixed with ASSET_CDN_HOST when configured, otherwise `path`
  # unchanged. Use this for emitting asset URLs in Ruby code that:
  #   - returns strings used directly as <img src> values (Administrate fields, etc.)
  #   - embeds asset URLs in API payloads sent to third parties (Dyte avatar, Captain default avatar)
  #   - generates inline-script asset URLs in ERB layouts
  # NOT a replacement for `image_url`/`asset_url` view helpers, which already
  # honor Rails' asset_host at runtime when ASSET_CDN_HOST is set.
  def asset_url(path)
    return path if path.blank?

    host = host_or_empty
    return path if host.empty?
    return path if path.match?(%r{\A(?:https?:)?//})

    "#{host}#{path}"
  end

  # Always returns an absolute URL. Falls back to FRONTEND_URL when no CDN host
  # is configured. Used for asset URLs embedded in third-party API payloads
  # (Dyte, Captain default avatar, Slack uploads fallback) where the receiver
  # must be able to fetch the resource regardless of where this Rails app lives.
  def asset_url_or_origin(path)
    return path if path.blank?
    return path if path.match?(%r{\A(?:https?:)?//})

    host = host_or_empty
    host = ENV.fetch('FRONTEND_URL', '').to_s.strip.sub(%r{/+\z}, '') if host.empty?

    "#{host}#{path}"
  end

  # Read ENV directly — matches config.action_controller.asset_host in
  # production.rb, which is also a boot-time ENV read. GlobalConfigService.load
  # would persist the ENV value into InstallationConfig and then prefer the DB
  # row on subsequent calls, so rotating ASSET_CDN_HOST would leave the SDK
  # snippets/globalConfig emitting the stale host while Rails helpers picked
  # up the new one. Treating this as a deploy-time setting only avoids drift.
  def host_or_empty
    ENV.fetch('ASSET_CDN_HOST', '').to_s.strip.sub(%r{/+\z}, '')
  end

  # Mutates @global_config in place, prefixing LOGO / LOGO_DARK / LOGO_THUMBNAIL
  # with ASSET_CDN_HOST so JS consumers reading `window.globalConfig.LOGO_THUMBNAIL`
  # directly get absolute URLs without needing to wrap via useAssetUrl. The
  # client-side wrappers stay for defense-in-depth (assetUrl is a no-op on
  # already-absolute URLs), but this ensures the serialized window.globalConfig
  # is itself complete.
  LOGO_KEYS = %w[LOGO LOGO_DARK LOGO_THUMBNAIL].freeze

  def normalize_logo_paths!(global_config)
    LOGO_KEYS.each do |key|
      global_config[key] = asset_url(global_config[key]) if global_config[key].present?
    end
    global_config
  end
end
