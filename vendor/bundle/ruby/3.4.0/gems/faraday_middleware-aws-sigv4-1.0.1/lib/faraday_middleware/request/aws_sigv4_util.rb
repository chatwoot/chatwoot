# frozen_string_literal: true

module FaradayMiddleware
  module AwsSigV4Util
    def seahorse_encode_query(url)
      return url unless url.query

      params = URI.decode_www_form(url.query)

      if params.any? { |_, v| v["\s"] }
        url = url.dup
        url.query = seahorse_encode_www_form(params)
      end

      url
    end

    def seahorse_encode_www_form(params)
      params.flat_map do |key, value|
        encoded_key = URI.encode_www_form_component(key)

        if value.nil?
          encoded_key
        else
          Array(value).map do |v|
            if v.nil?
              # nothing to do
            else
              "#{encoded_key}=#{Aws::Sigv4::Signer.uri_escape(v)}"
            end
          end
        end
      end.join('&')
    end
  end
end
