# frozen_string_literal: true

module Dry
  module Schema
    # Message objects used by message sets
    #
    # @api public
    class Message
      module Or
        # @api private
        def self.[](left, right, messages)
          msgs = [left, right].flatten
          paths = msgs.map(&:path)

          if paths.uniq.size == 1
            SinglePath.new(left, right, messages)
          elsif MultiPath.handler(right)
            if MultiPath.handler(left) && paths.uniq.size > 1
              MultiPath.new(left, right)
            else
              right
            end
          else
            msgs.max
          end
        end
      end
    end
  end
end
