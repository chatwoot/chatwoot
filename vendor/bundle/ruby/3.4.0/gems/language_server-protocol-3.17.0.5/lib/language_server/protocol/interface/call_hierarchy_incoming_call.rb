module LanguageServer
  module Protocol
    module Interface
      class CallHierarchyIncomingCall
        def initialize(from:, from_ranges:)
          @attributes = {}

          @attributes[:from] = from
          @attributes[:fromRanges] = from_ranges

          @attributes.freeze
        end

        #
        # The item that makes the call.
        #
        # @return [CallHierarchyItem]
        def from
          attributes.fetch(:from)
        end

        #
        # The ranges at which the calls appear. This is relative to the caller
        # denoted by [`this.from`](#CallHierarchyIncomingCall.from).
        #
        # @return [Range[]]
        def from_ranges
          attributes.fetch(:fromRanges)
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
