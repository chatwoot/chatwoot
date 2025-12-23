# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "gapic/rest/grpc_transcoder/http_binding"

module Gapic
  module Rest
    # @private
    # Transcodes a proto request message into HTTP Rest call components
    # using a configuration of bindings.
    # Internal doc go/actools-regapic-grpc-transcoding.
    class GrpcTranscoder
      def initialize bindings = nil
        @bindings = bindings || []
      end

      ##
      # @private
      # Creates a new trascoder that is a copy of this one, but with an additional
      # binding defined by the parameters.
      #
      # @param uri_method [Symbol] The rest verb for the binding.
      # @param uri_template [String] The string with uri template for the binding.
      #   This string will be expanded with the parameters from variable bindings.
      # @param matches [Array<Array>] Variable bindings in an array. Every element
      #   of the array is an [Array] triplet, where:
      #   - the first element is a [String] field path (e.g. `foo.bar`) in the request
      #     to bind to
      #   - the second element is a [Regexp] to match the field value
      #   - the third element is a [Boolean] whether the slashes in the field value
      #     should be preserved (as opposed to escaped) when expanding the uri template.
      # @param body [String, Nil] The body template, e.g. `*` or a field path.
      #
      # @return [Gapic::Rest::GrpcTranscoder] The updated transcoder.
      def with_bindings uri_method:, uri_template:, matches: [], body: nil
        binding = HttpBinding.create_with_validation(uri_method: uri_method,
                                                     uri_template: uri_template,
                                                     matches: matches,
                                                     body: body)
        GrpcTranscoder.new @bindings + [binding]
      end

      ##
      # @private
      # Performs the full grpc transcoding -- creating a REST request from the GRPC request
      # by matching the http bindings and choosing the last one to match.
      # From the matching binding and the request the following components of the REST request
      # are produced:
      # - A [Symbol] representing the Rest verb (e.g. `:get`)
      # - Uri [String] (e.g. `books/100:read`)
      # - Query string params in the form of key-value pairs [Array<Array{String, String}>]
      #   (e.g. [["foo", "bar"], ["baz", "qux"]])
      # - Body of the request [String]
      #
      # @param request [Object] The GRPC request object
      #
      # @return [Array] The components of the transcoded request.
      def transcode request
        # Using bindings in reverse here because of the "last one wins" rule
        @bindings.reverse.each do |http_binding|
          # The main reason we are using request.to_json here
          # is that the unset proto3_optional fields will not be
          # in that JSON, letting us skip the checks that would look like
          #   `request.respond_to?("has_#{key}?".to_sym) && !request.send("has_#{key}?".to_sym)`
          # The reason we set emit_defaults: true is to avoid
          # having to figure out default values for the required
          # fields at a runtime.
          #
          # Make a new one for each binding because extract_scalar_value! is destructive
          request_hash = JSON.parse request.to_json emit_defaults: true

          uri_values = bind_uri_values! http_binding, request_hash
          next if uri_values.any? { |_, value| value.nil? }

          # Note that the body template can only point to a top-level field,
          # so there is no need to split the path.
          next if http_binding.body && http_binding.body != "*" && !(request.respond_to? http_binding.body.to_sym)

          method = http_binding.method
          uri = expand_template http_binding.template, uri_values
          body, query_params = construct_body_query_params http_binding.body, request_hash, request

          return method, uri, query_params, body
        end

        raise ::Gapic::Common::Error,
              "Request object does not match any transcoding template. Cannot form a correct REST call."
      end

      private

      # Binds request values for the uri template expansion.
      # This method modifies the provided `request_hash` parameter.
      # Returned values are percent-escaped with slashes potentially preserved.
      # @param http_binding [Gapic::Rest::GrpcTranscoder::HttpBinding]
      #   Http binding to get the field bindings from.
      # @param request_hash [Hash]
      #   A hash of the GRPC request with the unset proto3_optional fields pre-removed.
      #   !!! This hash will be modified. The bound fields will be deleted. !!!
      # @return [Hash{String, String}]
      #   Name to value hash of the variables for the uri template expansion.
      #   The values are percent-escaped with slashes potentially preserved.
      def bind_uri_values! http_binding, request_hash
        http_binding.field_bindings.to_h do |field_binding|
          field_path_camel = field_binding.field_path.split(".").map { |part| camel_name_for part }.join(".")
          field_value = extract_scalar_value! request_hash, field_path_camel, field_binding.regex

          if field_value
            field_value = field_value.split("/").map { |segment| percent_escape segment }.join("/")
          end

          [field_binding.field_path, field_value]
        end
      end

      # Percent-escapes a string.
      # @param str [String] String to escape.
      # @return [String] Escaped string.
      def percent_escape str
        # `+` to represent spaces is not currently supported in Showcase server.
        CGI.escape(str).gsub("+", "%20")
      end

      # Constructs body and query parameters for the Rest request.
      # @param body_template [String, Nil] The template for the body, e.g. `*`.
      # @param request_hash_without_uri [Hash]
      #   The hash of the GRPC request with the unset proto3_optional fields
      #   and the values that are bound to URI removed.
      # @param request [Object] The GRPC request.
      # @return [Array{String, Array}] A pair of body and query parameters.
      def construct_body_query_params body_template, request_hash_without_uri, request
        body = ""
        query_params = []

        if body_template == "*"
          body = request_hash_without_uri.to_json
        elsif body_template && body_template != ""
          # Using a `request` here instead of `request_hash_without_uri`
          # because if `body` is bound to a message field,
          # the fields of the corresponding sub-message,
          # which were used when constructing the URI, should not be deleted
          # (as opposed to the case when `body` is `*`).
          #
          # The `request_hash_without_uri` at this point was mutated to delete these fields.
          #
          # Note 1: body template can only point to a top-level field.
          # Note 2: The field that body template points to can be null, in which case
          # an empty string should be sent. E.g. `Compute.Projects.SetUsageExportBucket`.
          request_body_field = request.send body_template.to_sym if request.respond_to? body_template.to_sym
          if request_body_field
            request_hash_without_uri.delete camel_name_for body_template
            body = request_body_field.to_json emit_defaults: true
          end

          query_params = build_query_params request_hash_without_uri
        else
          query_params = build_query_params request_hash_without_uri
        end

        [body, query_params]
      end

      # Builds query params for the REST request.
      # This function calls itself recursively for every submessage field, passing
      # the submessage hash as request and the path to the submessage field as a prefix.
      # @param request_hash [Hash]
      #   A hash of the GRPC request or the sub-request with the unset
      #   proto3_optional fields and the values that are bound to URI removed.
      # @param prefix [String] A prefix to form the correct query parameter key.
      # @return [Array{String, String}] Query string params as key-value pairs.
      def build_query_params request_hash, prefix = ""
        result = []
        request_hash.each do |key, value|
          full_key_name = "#{prefix}#{key}"
          case value
          when ::Array
            value.each do |_val|
              result.push "#{full_key_name}=#{value}"
            end
          when ::Hash
            result += build_query_params value, "#{full_key_name}."
          else
            result.push "#{full_key_name}=#{value}" unless value.nil?
          end
        end

        result
      end

      # Extracts a non-submessage non-array value from the request hash by path
      # if its string representation matches the regex provided.
      # This method modifies the provided `request_hash` parameter.
      # Returns nil if:
      # - the field is not found
      # - the field is a Message or an array,
      # - the regex does not match
      # @param request_hash [Hash]
      #   A hash of the GRPC request or the sub-request with the unset
      #   proto3_optional fields removed.
      #   !!! This hash will be modified. The extracted field will be deleted. !!!
      # @param field_path [String] A path to the field, e.g. `foo.bar`.
      # @param regex [Regexp] A regex to match on the field's string representation.
      # @return [String, Nil] the field's string representation or nil.
      def extract_scalar_value! request_hash, field_path, regex
        parent, name = find_value request_hash, field_path
        value = parent.delete name

        # Covers the case where in `foo.bar.baz`, `baz` is still a submessage or an array.
        return nil if value.is_a?(::Hash) || value.is_a?(::Array)
        value.to_s if value.to_s =~ regex
      end

      # Finds a value in the hash by path.
      # @param request_hash [Hash] A hash of the GRPC request or the sub-request.
      # @param field_path [String] A path of the field, e.g. `foo.bar`.
      def find_value request_hash, field_path
        path_split = field_path.split "."

        value_parent = nil
        value = request_hash
        last_field_name = nil
        path_split.each do |curr_field|
          # Covers the case when in `foo.bar.baz`, `bar` is not a submessage field
          # or is a submessage field initialized with nil.
          return {}, nil unless value.is_a? ::Hash
          value_parent = value
          last_field_name = curr_field
          value = value[curr_field]
        end

        [value_parent, last_field_name]
      end

      # Performs variable expansion on the template using the bindings provided
      # @param template [String] The Uri template.
      # @param bindings [Hash{String, String}]
      #   The variable bindings. The values should be percent-escaped
      #   (with slashes potentially preserved).
      # @return [String] The expanded template.
      def expand_template template, bindings
        result = template
        bindings.each do |name, value|
          result = result.gsub "{#{name}}", value
        end
        result
      end

      ##
      # Converts a snake_case parameter name into camelCase for query string parameters.
      # @param attr_name [String] Parameter name.
      # @return [String] Camel-cased parameter name.
      def camel_name_for attr_name
        parts = attr_name.split "_"
        first_part = parts[0]
        other_parts = parts[1..]
        other_parts_pascal = other_parts.map(&:capitalize).join
        "#{first_part}#{other_parts_pascal}"
      end
    end
  end
end
