Rails.application.configure do
  config.action_dispatch.trusted_proxies = ENV.fetch('TRUSTED_PROXIES', '')
                                              .split(',')
                                              .map(&:strip)
                                              .reject(&:empty?)
                                              .filter_map do |proxy|
                                                IPAddr.new(proxy)
                                              rescue IPAddr::InvalidAddressError => e
                                                Rails.logger.warn "Invalid IP: #{proxy}"
                                                nil # return nil for invalid entries
                                              end
end
