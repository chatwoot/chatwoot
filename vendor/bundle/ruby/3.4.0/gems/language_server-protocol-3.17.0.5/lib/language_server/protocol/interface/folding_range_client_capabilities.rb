module LanguageServer
  module Protocol
    module Interface
      class FoldingRangeClientCapabilities
        def initialize(dynamic_registration: nil, range_limit: nil, line_folding_only: nil, folding_range_kind: nil, folding_range: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:rangeLimit] = range_limit if range_limit
          @attributes[:lineFoldingOnly] = line_folding_only if line_folding_only
          @attributes[:foldingRangeKind] = folding_range_kind if folding_range_kind
          @attributes[:foldingRange] = folding_range if folding_range

          @attributes.freeze
        end

        #
        # Whether implementation supports dynamic registration for folding range
        # providers. If this is set to `true` the client supports the new
        # `FoldingRangeRegistrationOptions` return value for the corresponding
        # server capability as well.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The maximum number of folding ranges that the client prefers to receive
        # per document. The value serves as a hint, servers are free to follow the
        # limit.
        #
        # @return [number]
        def range_limit
          attributes.fetch(:rangeLimit)
        end

        #
        # If set, the client signals that it only supports folding complete lines.
        # If set, client will ignore specified `startCharacter` and `endCharacter`
        # properties in a FoldingRange.
        #
        # @return [boolean]
        def line_folding_only
          attributes.fetch(:lineFoldingOnly)
        end

        #
        # Specific options for the folding range kind.
        #
        # @return [{ valueSet?: string[]; }]
        def folding_range_kind
          attributes.fetch(:foldingRangeKind)
        end

        #
        # Specific options for the folding range.
        #
        # @return [{ collapsedText?: boolean; }]
        def folding_range
          attributes.fetch(:foldingRange)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
