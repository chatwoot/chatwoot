module StripeV2Client
  class << self
    def request(method, path, params = {}, options = {})
      api_key = options[:api_key] || ENV.fetch('STRIPE_SECRET_KEY', nil)
      stripe_version = options[:stripe_version] || '2025-08-27.preview'

      uri = URI("https://api.stripe.com#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = build_request(method, uri, params, path)
      request['Authorization'] = "Bearer #{api_key}"
      request['Stripe-Version'] = stripe_version

      response = http.request(request)
      parse_response(response)
    end

    private

    def build_request(method, uri, params, path)
      case method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        req = Net::HTTP::Post.new(uri)
        if v2_endpoint?(path)
          # V2 endpoints use JSON
          req.body = params.to_json unless params.empty?
          req['Content-Type'] = 'application/json'
        else
          # V1 endpoints (including checkout sessions) use form data
          # even with preview API versions
          req.body = encode_nested_params(params) unless params.empty?
          req['Content-Type'] = 'application/x-www-form-urlencoded'
        end
        req
      when :delete
        Net::HTTP::Delete.new(uri)
      end
    end

    def v2_endpoint?(path)
      path.start_with?('/v2/')
    end

    # Encode nested parameters for form submission
    # Stripe expects nested params like: checkout_items[0][type]=value
    def encode_nested_params(params, prefix = nil)
      pairs = []
      params.each do |key, value|
        full_key = prefix ? "#{prefix}[#{key}]" : key.to_s
        pairs.concat(encode_param_value(full_key, value))
      end
      pairs.join('&')
    end

    def encode_param_value(key, value)
      case value
      when Hash
        [encode_nested_params(value, key)]
      when Array
        value.each_with_index.map { |item, index| encode_nested_params(item, "#{key}[#{index}]") }
      when true, false
        ["#{CGI.escape(key)}=#{value}"]
      when nil
        []
      else
        ["#{CGI.escape(key)}=#{CGI.escape(value.to_s)}"]
      end
    end

    def parse_response(response)
      body = JSON.parse(response.body)

      # Check for Stripe error responses
      if body.is_a?(Hash) && body['error']
        error = body['error']
        raise Stripe::StripeError, "#{error['code']}: #{error['message']}"
      end

      # Convert to OpenStruct for dot notation access (mimicking Stripe SDK objects)
      case body
      when Hash
        recursive_to_struct(body)
      when Array
        body.map { |item| recursive_to_struct(item) }
      else
        body
      end
    rescue JSON::ParserError
      response.body
    end

    def recursive_to_struct(hash)
      return hash unless hash.is_a?(Hash)

      OpenStruct.new(hash.transform_values do |value|
        case value
        when Hash
          recursive_to_struct(value)
        when Array
          value.map { |item| item.is_a?(Hash) ? recursive_to_struct(item) : item }
        else
          value
        end
      end)
    end
  end
end
