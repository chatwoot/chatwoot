# frozen_string_literal: true

module Datadog
  module AppSec
    module Utils
      module HTTP
        # Implementation of media type for content negotiation
        #
        # See:
        # - https://www.rfc-editor.org/rfc/rfc7231#section-5.3.1
        # - https://www.rfc-editor.org/rfc/rfc7231#section-5.3.2
        class MediaType
          class ParseError < ::StandardError
          end

          WILDCARD = '*'

          # See: https://www.rfc-editor.org/rfc/rfc7230#section-3.2.6
          TOKEN_RE = /[-#$%&'*+.^_`|~A-Za-z0-9]+/.freeze

          # See: https://www.rfc-editor.org/rfc/rfc7231#section-3.1.1.1
          PARAMETER_RE = %r{ # rubocop:disable Style/RegexpLiteral
            (?:
              (?<parameter_name>#{TOKEN_RE})
              =
              (?:
                (?<parameter_value>#{TOKEN_RE})
                |
                "(?<parameter_value>[^"]+)"
              )
            )
          }ix.freeze

          # See: https://www.rfc-editor.org/rfc/rfc7231#section-3.1.1.1
          MEDIA_TYPE_RE = %r{
            \A
            (?<type>#{TOKEN_RE})/(?<subtype>#{TOKEN_RE})
            (?<parameters>
              (?:
                \s*;\s*
                #{PARAMETER_RE}
              )*
            )
            \Z
          }ix.freeze

          attr_reader :type, :subtype, :parameters

          def initialize(media_type)
            media_type_match = MEDIA_TYPE_RE.match(media_type)

            raise ParseError, media_type.inspect if media_type_match.nil?

            @type = (media_type_match['type'] || WILDCARD).downcase
            @subtype = (media_type_match['subtype'] || WILDCARD).downcase
            @parameters = {}

            parameters = media_type_match['parameters']

            return if parameters.nil?

            parameters.split(';').map(&:strip).each do |parameter|
              parameter_match = PARAMETER_RE.match(parameter)

              next if parameter_match.nil?

              parameter_name = parameter_match['parameter_name']
              parameter_value = parameter_match['parameter_value']

              next if parameter_name.nil? || parameter_value.nil?

              @parameters[parameter_name.downcase] = parameter_value.downcase
            end
          end

          def to_s
            s = +"#{@type}/#{@subtype}"

            s << ';' << @parameters.map { |k, v| "#{k}=#{v}" }.join(';') if @parameters.count > 0

            s
          end
        end
      end
    end
  end
end
