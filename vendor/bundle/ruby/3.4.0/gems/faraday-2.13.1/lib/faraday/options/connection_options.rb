# frozen_string_literal: true

module Faraday
  # @!parse
  #   # ConnectionOptions contains the configurable properties for a Faraday
  #   # connection object.
  #   class ConnectionOptions < Options; end
  ConnectionOptions = Options.new(:request, :proxy, :ssl, :builder, :url,
                                  :parallel_manager, :params, :headers,
                                  :builder_class) do
    options request: RequestOptions, ssl: SSLOptions

    memoized(:request) { self.class.options_for(:request).new }

    memoized(:ssl) { self.class.options_for(:ssl).new }

    memoized(:builder_class) { RackBuilder }

    def new_builder(block)
      builder_class.new(&block)
    end
  end
end
