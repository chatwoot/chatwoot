# frozen_string_literal: true

module Rack
  module Test
    module Utils # :nodoc:
      include Rack::Utils
      extend self

      # Build a query string for the given value and prefix. The value
      # can be an array or hash of parameters.
      def build_nested_query(value, prefix = nil)
        case value
        when Array
          if value.empty?
            "#{prefix}[]="
          else
            prefix += "[]" unless unescape(prefix).end_with?('[]')
            value.map do |v|
              build_nested_query(v, prefix.to_s)
            end.join('&')
          end
        when Hash
          value.map do |k, v|
            build_nested_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          end.join('&')
        when NilClass
          prefix.to_s
        else
          "#{prefix}=#{escape(value)}"
        end
      end

      # Build a multipart body for the given params.
      def build_multipart(params, _first = true, multipart = false)
        raise ArgumentError, 'value must be a Hash' unless params.is_a?(Hash)

        unless multipart
          query = lambda { |value|
            case value
            when Array
              value.each(&query)
            when Hash
              value.values.each(&query)
            when UploadedFile
              multipart = true
            end
          }
          params.values.each(&query)
          return nil unless multipart
        end

        params = normalize_multipart_params(params, true)

        buffer = String.new
        build_parts(buffer, params)
        buffer
      end

      private

      # Return a flattened hash of parameter values based on the given params.
      def normalize_multipart_params(params, first=false)
        flattened_params = {}

        params.each do |key, value|
          k = first ? key.to_s : "[#{key}]"

          case value
          when Array
            value.map do |v|
              if v.is_a?(Hash)
                nested_params = {}
                normalize_multipart_params(v).each do |subkey, subvalue|
                  nested_params[subkey] = subvalue
                end
                (flattened_params["#{k}[]"] ||= []) << nested_params
              else
                flattened_params["#{k}[]"] = value
              end
            end
          when Hash
            normalize_multipart_params(value).each do |subkey, subvalue|
              flattened_params[k + subkey] = subvalue
            end
          else
            flattened_params[k] = value
          end
        end

        flattened_params
      end

      # Build the multipart content for uploading.
      def build_parts(buffer, parameters)
        _build_parts(buffer, parameters)
        buffer << END_BOUNDARY
      end

      # Append each multipart parameter value to the buffer.
      def _build_parts(buffer, parameters)
        parameters.map do |name, value|
          if name =~ /\[\]\Z/ && value.is_a?(Array) && value.all? { |v| v.is_a?(Hash) }
            value.each do |hash|
              new_value = {}
              hash.each { |k, v| new_value[name + k] = v }
              _build_parts(buffer, new_value)
            end
          else
            [value].flatten.map do |v|
              if v.respond_to?(:original_filename)
                build_file_part(buffer, name, v)
              else
                build_primitive_part(buffer, name, v)
              end
            end
          end
        end
      end

      # Append the multipart fragment for a parameter that isn't a file upload to the buffer.
      def build_primitive_part(buffer, parameter_name, value)
        buffer <<
          START_BOUNDARY <<
          "content-disposition: form-data; name=\"" <<
          parameter_name.to_s.b <<
          "\"\r\n\r\n" <<
          value.to_s.b <<
          "\r\n"
        buffer
      end

      # Append the multipart fragment for a parameter that is a file upload to the buffer.
      def build_file_part(buffer, parameter_name, uploaded_file)
        buffer <<
          START_BOUNDARY <<
          "content-disposition: form-data; name=\"" <<
          parameter_name.to_s.b <<
          "\"; filename=\"" <<
          escape_path(uploaded_file.original_filename).b <<
          "\"\r\ncontent-type: " <<
          uploaded_file.content_type.to_s.b <<
          "\r\ncontent-length: " <<
          uploaded_file.size.to_s.b <<
          "\r\n\r\n"

        # Handle old versions of Capybara::RackTest::Form::NilUploadedFile
        if uploaded_file.respond_to?(:set_encoding)
          uploaded_file.set_encoding(Encoding::BINARY)
          uploaded_file.append_to(buffer)
        end

        buffer << "\r\n"
      end
    end
  end
end
