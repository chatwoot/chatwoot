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

module Gapic
  module Rest
    class GrpcTranscoder
      ##
      # @private
      # A single binding for GRPC-REST transcoding of a request
      # It includes a uri template with bound field parameters, a HTTP method type,
      # and a body template
      #
      # @attribute [r] method
      #   @return [Symbol] The REST verb for the request.
      # @attribute [r] template
      #   @return [String] The URI template for the request.
      # @attribute [r] field_bindings
      #   @return [Array<Gapic::Rest::GrpcTranscoder::HttpBinding::FieldBinding>]
      #     The field bindings for the URI template variables.
      # @attribute [r] body
      #   @return [String] The body template for the request.
      class HttpBinding
        attr_reader :method
        attr_reader :template
        attr_reader :field_bindings
        attr_reader :body

        def initialize method, template, field_bindings, body
          @method = method
          @template = template
          @field_bindings = field_bindings
          @body = body
        end

        ##
        # @private
        # Creates a new HttpBinding.
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
        # @return [Gapic::Rest::GrpcTranscoder::HttpBinding] The new binding.
        def self.create_with_validation uri_method:, uri_template:, matches: [], body: nil
          template = uri_template

          matches.each do |name, _regex, _preserve_slashes|
            unless uri_template =~ /({#{Regexp.quote name}})/
              err_msg = "Binding configuration is incorrect: missing parameter in the URI template.\n" \
                        "Parameter `#{name}` is specified for matching but there is no corresponding parameter " \
                        "`{#{name}}` in the URI template."
              raise ::Gapic::Common::Error, err_msg
            end

            template = template.gsub "{#{name}}", ""
          end

          if template =~ /{([a-zA-Z_.]+)}/
            err_name = Regexp.last_match[1]
            err_msg = "Binding configuration is incorrect: missing match configuration.\n" \
                      "Parameter `{#{err_name}}` is specified in the URI template but there is no " \
                      "corresponding match configuration for `#{err_name}`."
            raise ::Gapic::Common::Error, err_msg
          end

          if body&.include? "."
            raise ::Gapic::Common::Error,
                  "Provided body template `#{body}` points to a field in a sub-message. This is not supported."
          end

          field_bindings = matches.map do |name, regex, preserve_slashes|
            HttpBinding::FieldBinding.new name, regex, preserve_slashes
          end

          HttpBinding.new uri_method, uri_template, field_bindings, body
        end

        # A single binding for a field of a request message.
        # @attribute [r] field_path
        #   @return [String] The path of the bound field, e.g. `foo.bar`.
        # @attribute [r] regex
        #   @return [Regexp] The regex to match on the bound field's string representation.
        # @attribute [r] preserve_slashes
        #   @return [Boolean] Whether the slashes in the field value should be preserved
        #     (as opposed to percent-escaped)
        class FieldBinding
          attr_reader :field_path
          attr_reader :regex
          attr_reader :preserve_slashes

          def initialize field_path, regex, preserve_slashes
            @field_path = field_path
            @regex = regex
            @preserve_slashes = preserve_slashes
          end
        end
      end
    end
  end
end
