Rails.application.configure do
  config.action_dispatch.trusted_proxies = ENV.fetch('TRUSTED_PROXIES', '')
    .split(',')
    .map(&:strip)
    .reject(&:empty?)
    .map { |proxy| IPAddr.new(proxy) }
end
