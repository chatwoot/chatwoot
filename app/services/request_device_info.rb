# Resolves a human-readable device/browser description from a request, handling
# the Chatwoot mobile app's custom headers and legacy mobile UAs the same way
# session tracking does, so the "Unknown Browser" fallback is not shown for the app.
class RequestDeviceInfo
  # CFNetwork UAs cannot distinguish iPhone from iPad; both get labelled iPhone here.
  LEGACY_MOBILE_UAS = [
    { match: %r{\Aokhttp/}, platform: 'Android', device: 'Android' },
    { match: %r{\AChatwoot/.*CFNetwork.*Darwin}, platform: 'iPhone', device: 'iPhone' }
  ].freeze
  private_constant :LEGACY_MOBILE_UAS

  def initialize(request)
    @request = request
  end

  # Full attribute hash used to persist a user_session row.
  def to_h
    @to_h ||= mobile_client_headers || browser_attributes
  end

  def browser_name
    to_h[:browser_name]
  end

  # A clean "on X" label: the device for mobile clients, the OS for desktop browsers.
  def platform_label
    @mobile ? to_h[:device_name] : to_h[:platform_name]
  end

  private

  def mobile_client_headers
    name = @request.headers['X-Chatwoot-Client-Name']
    return nil if name.blank?

    @mobile = true
    platform = @request.headers['X-Chatwoot-Platform']
    model = @request.headers['X-Chatwoot-Device-Model']

    {
      browser_name: name,
      browser_version: @request.headers['X-Chatwoot-Client-Version'],
      device_name: device_name_for_icon(platform, model),
      platform_name: model,
      platform_version: @request.headers['X-Chatwoot-Platform-Version']
    }
  end

  def browser_attributes
    browser = Browser.new(@request.user_agent)

    attrs = {
      browser_name: browser.name,
      browser_version: browser.full_version,
      device_name: browser.device.name,
      platform_name: browser.platform.name,
      platform_version: browser.platform.version
    }

    patch_for_legacy_mobile(attrs)
  end

  def device_name_for_icon(platform, model)
    normalized_platform = platform.to_s.downcase
    return 'iPad' if normalized_platform == 'ios' && model.to_s.include?('iPad')
    return 'iPhone' if normalized_platform == 'ios'

    'Android'
  end

  def patch_for_legacy_mobile(attrs)
    return attrs unless attrs[:browser_name] == 'Unknown Browser'

    hit = LEGACY_MOBILE_UAS.find { |m| @request.user_agent.to_s.match?(m[:match]) }
    return attrs unless hit

    @mobile = true
    attrs.merge(
      browser_name: 'Chatwoot Mobile',
      browser_version: nil,
      platform_name: hit[:platform],
      platform_version: nil,
      device_name: hit[:device]
    )
  end
end
