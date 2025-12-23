# frozen_string_literal: true

module Dry
  module Schema
    class Message
      module Or
        # A message type used by OR operations with the same path
        #
        # @api public
        class SinglePath < Abstract
          # @api private
          attr_reader :path

          # @api private
          attr_reader :_path

          # @api private
          attr_reader :messages

          # @api private
          def initialize(*args, messages)
            super(*args.map { [_1].flatten })
            @messages = messages
            message = left.first
            @path = message.path
            @_path = message._path
          end

          # Dump a message into a string
          #
          # Both sides of the message will be joined using translated
          # value under `dry_schema.or` message key
          #
          # @see Message#dump
          #
          # @return [String]
          #
          # @api public
          def dump
            @dump ||= [*left, *right].map(&:dump).join(" #{messages[:or]} ")
          end
          alias_method :to_s, :dump

          # Dump an `or` message into a hash
          #
          # @see Message#to_h
          #
          # @return [String]
          #
          # @api public
          def to_h
            @to_h ||= _path.to_h(dump)
          end

          # @api private
          def to_a
            @to_a ||= [*left, *right]
          end

          # @api private
          def to_or(root)
            to_ored = [left, right].map do |msgs|
              msgs.map { _1.to_or(root) }
            end

            self.class.new(*to_ored, messages)
          end
        end
      end
    end
  end
end
