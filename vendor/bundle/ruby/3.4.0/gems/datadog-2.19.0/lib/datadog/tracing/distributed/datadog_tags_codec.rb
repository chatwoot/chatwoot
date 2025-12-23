# frozen_string_literal: true

module Datadog
  module Tracing
    module Distributed
      # Encodes and decodes distributed 'x-datadog-tags' tags for transport
      # to and from external processes.
      module DatadogTagsCodec
        # Backport `Regexp::match?` because it is measurably the most performant
        # way to check if a string matches a regular expression.
        module RefineRegexp
          unless Regexp.method_defined?(:match?)
            refine ::Regexp do
              def match?(*args)
                !match(*args).nil?
              end
            end
          end
        end
        using RefineRegexp

        # ASCII characters 32-126, except `,`, `=`, and ` `. At least one character.
        VALID_KEY_CHARS = /\A(?:(?![,= ])[\u0020-\u007E])+\Z/.freeze
        # ASCII characters 32-126, except `,`. At least one character.
        VALID_VALUE_CHARS = /\A(?:(?!,)[\u0020-\u007E])+\Z/.freeze

        # Serializes a {Hash<String,String>} into a `x-datadog-tags`-compatible
        # String.
        #
        # @param tags [Hash<String,String>] trace tag hash
        # @return [String] serialized tags hash
        # @raise [EncodingError] if tags cannot be serialized to the `x-datadog-tags` format
        def self.encode(tags)
          begin
            tags.map do |raw_key, raw_value|
              key = raw_key.to_s
              value = raw_value.to_s

              raise EncodingError, "Invalid key `#{key}` for value `#{value}`" unless VALID_KEY_CHARS.match?(key)
              raise EncodingError, "Invalid value `#{value}` for key `#{key}`" unless VALID_VALUE_CHARS.match?(value)

              "#{key}=#{value.strip}"
            end.join(',')
          rescue => e
            raise EncodingError, "Error encoding tags `#{tags}`: `#{e}`"
          end
        end

        # Deserializes a `x-datadog-tags`-formatted String into a {Hash<String,String>}.
        #
        # @param string [String] tags as serialized by {#encode}
        # @return [Hash<String,String>] decoded input as a hash of strings
        # @raise [DecodingError] if string does not conform to the `x-datadog-tags` format
        def self.decode(string)
          result = Hash[string.split(',').map do |raw_tag|
            raw_tag.split('=', 2).tap do |raw_key, raw_value|
              key = raw_key.to_s
              value = raw_value.to_s

              raise DecodingError, "Invalid key: #{key}" unless VALID_KEY_CHARS.match?(key)
              raise DecodingError, "Invalid value: #{value}" unless VALID_VALUE_CHARS.match?(value)

              value.strip!
            end
          end]

          raise DecodingError, "Invalid empty tags: #{string}" if result.empty? && !string.empty?

          result
        end

        # An error occurred during distributed tags encoding.
        # See {#message} for more information.
        class EncodingError < StandardError
        end

        # An error occurred during distributed tags decoding.
        # See {#message} for more information.
        class DecodingError < StandardError
        end
      end
    end
  end
end
