# frozen_string_literal: true

module Dry
  module Schema
    module Extensions
      module Hints
        # Get errors exclusively without hints
        #
        # @api public
        module ResultMethods
          # Return error messages exclusively
          #
          # @see Result#errors
          #
          # @return [MessageSet]
          #
          # @api public
          def errors(options = EMPTY_HASH)
            message_set(options.merge(hints: false))
          end

          # Get all messages including hints
          #
          # @see #message_set
          #
          # @return [MessageSet]
          #
          # @api public
          def messages(options = EMPTY_HASH)
            message_set(options)
          end

          # Get hints exclusively without errors
          #
          # @see #message_set
          #
          # @return [MessageSet]
          #
          # @api public
          def hints(options = EMPTY_HASH)
            message_set(options.merge(failures: false))
          end
        end
      end
    end
  end
end
