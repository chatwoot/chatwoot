module PortalImageHelper
  # Relative paths follow the Help Center's current domain without changing saved content.
  def portal_image_src(url)
    begin
      source = URI.parse(url)
    rescue URI::InvalidURIError
      return url
    end
    return url unless source.is_a?(URI::HTTP) && source.userinfo.nil?
    return url unless source.path.start_with?("#{ActiveStorage.routes_prefix}/") && portal_image_origin?(source)

    source.request_uri + (source.fragment ? "##{source.fragment}" : '')
  end

  private

  def portal_image_origin?(source)
    installation_urls = [ENV.fetch('FRONTEND_URL', nil), ENV.fetch('HELPCENTER_URL', nil)].filter_map(&:presence)
    installation_urls.any? do |value|
      base = URI.parse(value)
      [source.scheme, source.host&.downcase, source.port] == [base.scheme, base.host&.downcase, base.port]
    end
  end
end
