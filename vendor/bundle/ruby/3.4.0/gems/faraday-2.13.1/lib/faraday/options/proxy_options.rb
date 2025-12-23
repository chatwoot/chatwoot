# frozen_string_literal: true

module Faraday
  # @!parse
  #   # ProxyOptions contains the configurable properties for the proxy
  #   # configuration used when making an HTTP request.
  #   class ProxyOptions < Options; end
  ProxyOptions = Options.new(:uri, :user, :password) do
    extend Forwardable
    def_delegators :uri, :scheme, :scheme=, :host, :host=, :port, :port=,
                   :path, :path=

    def self.from(value)
      case value
      when ''
        value = nil
      when String
        # URIs without a scheme should default to http (like 'example:123').
        # This fixes #1282 and prevents a silent failure in some adapters.
        value = "http://#{value}" unless value.include?('://')
        value = { uri: Utils.URI(value) }
      when URI
        value = { uri: value }
      when Hash, Options
        if value[:uri]
          value = value.dup.tap do |duped|
            duped[:uri] = Utils.URI(duped[:uri])
          end
        end
      end

      super(value)
    end

    memoized(:user) { uri&.user && Utils.unescape(uri.user) }
    memoized(:password) { uri&.password && Utils.unescape(uri.password) }
  end
end
