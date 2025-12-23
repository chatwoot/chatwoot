# frozen_string_literal: true

require_relative 'media_type'

module Datadog
  module AppSec
    module Utils
      module HTTP
        # Implementation of media range for content negotiation
        class MediaRange
          class ParseError < ::StandardError
          end

          WILDCARD = '*'
          WILDCARD_RE = ::Regexp.escape(WILDCARD)

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

          # See: https://www.rfc-editor.org/rfc/rfc7231#section-5.3.2
          ACCEPT_EXT_RE = %r{ # rubocop:disable Style/RegexpLiteral
            (?:
              (?<ext_name>#{TOKEN_RE})
              =
              (?:
                (?<ext_value>#{TOKEN_RE})
                |
                "(?<ext_value>[^"]+)"
              )
            )
          }ix.freeze

          # See: https://www.rfc-editor.org/rfc/rfc7231#section-5.3.1
          QVALUE_RE = %r{ # rubocop:disable Style/RegexpLiteral
            0(?:\.\d{1,3})?
            |
            1(?:\.0{1,3})?
          }ix.freeze

          # See: https://www.rfc-editor.org/rfc/rfc7231#section-5.3.2
          MEDIA_RANGE_RE = %r{
            \A
            (?:
              (?<type>#{WILDCARD_RE})/(?<subtype>#{WILDCARD_RE})
              |
              (?<type>#{TOKEN_RE})/(?<subtype>#{WILDCARD_RE})
              |
              (?<type>#{TOKEN_RE})/(?<subtype>#{TOKEN_RE})
            )
            (?<parameters>
              (?:
                \s*;\s*
                (?!q=)
                #{PARAMETER_RE}
              )*
            )
            (?<accept_params>
              (?<weight>
                \s*;\s*
                (?:q=
                  (?<quality>
                    #{QVALUE_RE}
                  )
                )
              )
              (?<accept_exts>
                (?<accept_ext>
                  (?:
                    \s*;\s*
                    (?!q=)
                    #{ACCEPT_EXT_RE}
                  )*
                )
              )
            )?
            \Z
          }ix.freeze

          attr_reader :type, :subtype, :quality, :parameters, :accept_ext

          def initialize(media_range) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            media_range_match = MEDIA_RANGE_RE.match(media_range)

            raise ParseError, media_range.inspect if media_range_match.nil?

            @type = (media_range_match['type'] || WILDCARD).downcase
            @subtype = (media_range_match['subtype'] || WILDCARD).downcase
            @quality = (media_range_match['quality'] || 1.0).to_f
            @parameters = {}
            @accept_ext = {}

            parameters = media_range_match['parameters']

            return if parameters.nil?

            parameters.split(';').map(&:strip).each do |parameter|
              parameter_match = PARAMETER_RE.match(parameter)

              next if parameter_match.nil?

              parameter_name = parameter_match['parameter_name']
              parameter_value = parameter_match['parameter_value']

              next if parameter_name.nil? || parameter_value.nil?

              @parameters[parameter_name.downcase] = parameter_value.downcase
            end

            accept_exts = media_range_match['accept_exts']

            return if accept_exts.nil?

            accept_exts.split(';').map(&:strip).each do |ext|
              ext_match = ACCEPT_EXT_RE.match(ext)

              next if ext_match.nil?

              ext_name = ext_match['ext_name']
              ext_value = ext_match['ext_value']

              next if ext_name.nil? || ext_value.nil?

              @accept_ext[ext_name.downcase] = ext_value.downcase
            end
          end

          # Compare two MediaRange for ordering
          def <=>(other)
            unless (q = quality <=> other.quality) == 0 || q.nil?
              return q
            end

            if (s = specificity <=> other.specificity) != 0
              return s
            end

            unless wildcard?(:type)
              if wildcard?(:subtype) && !other.wildcard?(:subtype)
                return -1
              elsif !wildcard?(:subtype) && other.wildcard?(:subtype)
                return 1
              end
            end

            if wildcard?(:type) && !other.wildcard?(:type)
              return -1
            elsif !wildcard?(:type) && other.wildcard?(:type)
              return 1
            end

            0
          end

          # Compare with a MediaType for match
          #
          # returns true if the MediaType is accepted by this MediaRange
          def ===(other)
            return self === MediaType.new(other) if other.is_a?(::String)

            type == other.type && subtype == other.subtype && other.parameters.all? { |k, v| parameters[k] == v } ||
              type == other.type && wildcard?(:subtype) ||
              wildcard?(:type) && wildcard?(:subtype)
          end

          def specificity
            @parameters.count
          end

          def wildcard?(field = nil)
            return wildcard?(:type) || wildcard?(:subtype) if field.nil?

            instance_variable_get(:"@#{field}") == WILDCARD
          end

          def to_s
            s = +"#{@type}/#{@subtype}"

            s << ';' << @parameters.map { |k, v| "#{k}=#{v}" }.join(';') if @parameters.count > 0
            s << ";q=#{@quality}" if @quality < 1.0
            s << ';' << @accept_ext.map { |k, v| "#{k}=#{v}" }.join(';') if @accept_ext.count > 0

            s
          end
        end
      end
    end
  end
end
