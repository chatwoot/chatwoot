# frozen_string_literal: true

module Faraday
  # @!parse
  #   # RequestOptions contains the configurable properties for a Faraday request.
  #   class RequestOptions < Options; end
  RequestOptions = Options.new(:params_encoder, :proxy, :bind,
                               :timeout, :open_timeout, :read_timeout,
                               :write_timeout, :boundary, :oauth,
                               :context, :on_data) do
    def []=(key, value)
      if key && key.to_sym == :proxy
        super(key, value ? ProxyOptions.from(value) : nil)
      else
        super(key, value)
      end
    end

    def stream_response?
      on_data.is_a?(Proc)
    end
  end
end
