# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # @api private
    class MessageCompiler
      # Optimized option hash used by visitor methods in message compiler
      #
      # @api private
      class VisitorOpts < Hash
        # @api private
        def self.new
          opts = super
          opts[:path] = EMPTY_ARRAY
          opts[:message_type] = :failure
          opts[:current_messages] = EMPTY_ARRAY.dup
          opts
        end

        # @api private
        def path
          self[:path]
        end

        # @api private
        def call(other)
          merge(other.update(path: [*path, *other[:path]]))
        end

        def dup(current_messages = EMPTY_ARRAY.dup)
          opts = super()
          opts[:current_messages] = current_messages
          opts
        end

        def key_failure?(path)
          failures.any? { |f| f.path == path && f.predicate.equal?(:key?) }
        end

        def failures
          current_messages.reject(&:hint?)
        end

        def hints
          current_messages.select(&:hint?)
        end

        def current_messages
          self[:current_messages]
        end
      end
    end
  end
end
