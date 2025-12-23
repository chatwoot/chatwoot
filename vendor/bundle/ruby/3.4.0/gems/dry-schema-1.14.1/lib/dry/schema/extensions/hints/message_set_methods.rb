# frozen_string_literal: true

module Dry
  module Schema
    module Extensions
      module Hints
        # Hint extensions for MessageSet
        #
        # @api public
        module MessageSetMethods
          # Filtered message hints from all messages
          #
          # @return [Array<Message::Hint>]
          attr_reader :hints

          # Configuration option to enable/disable showing errors
          #
          # @return [Boolean]
          attr_reader :failures

          # @api private
          def initialize(messages, options = EMPTY_HASH)
            super
            @hints = messages.select(&:hint?)
            @failures = options.fetch(:failures, true)
          end

          # Dump message set to a hash with either all messages or just hints
          #
          # @see MessageSet#to_h
          # @see ResultMethods#hints
          #
          # @return [Hash<Symbol=>Array<String>>]
          #
          # @api public
          def to_h
            @to_h ||= failures ? messages_map : messages_map(hints)
          end
          alias_method :to_hash, :to_h
        end
      end
    end
  end
end
