# frozen_string_literal: true

require "dry/schema/extensions/hints/compiler_methods"
require "dry/schema/extensions/hints/message_compiler_methods"
require "dry/schema/extensions/hints/message_set_methods"
require "dry/schema/extensions/hints/result_methods"

module Dry
  module Schema
    # Hint-specific Message extensions
    #
    # @see Message
    #
    # @api public
    class Message
      # Hints extension for Or messages
      #
      # @see Message::Or
      #
      # @api public
      module Or
        class SinglePath
          # @api private
          def hint?
            false
          end
        end

        class MultiPath
          # @api private
          def hint?
            false
          end
        end
      end

      # @api private
      def hint?
        false
      end
    end

    # A hint message sub-type
    #
    # @api private
    class Hint < Message
      # @api private
      def hint?
        true
      end
    end

    # Hints extensions
    module Extensions
      # @api private
      module Hints
      end

      Compiler.prepend(Hints::CompilerMethods)
      MessageCompiler.prepend(Hints::MessageCompilerMethods)
      MessageSet.prepend(Hints::MessageSetMethods)
      Result.prepend(Hints::ResultMethods)
    end
  end
end
