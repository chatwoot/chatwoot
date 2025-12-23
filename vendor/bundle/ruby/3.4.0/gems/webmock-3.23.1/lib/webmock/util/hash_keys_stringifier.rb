# frozen_string_literal: true

module WebMock
  module Util
    class HashKeysStringifier

      def self.stringify_keys!(arg, options = {})
        case arg
        when Array
          arg.map { |elem|
            options[:deep] ? stringify_keys!(elem, options) : elem
          }
        when Hash
          Hash[
            *arg.map { |key, value|
              k = key.is_a?(Symbol) ? key.to_s : key
              v = (options[:deep] ? stringify_keys!(value, options) : value)
              [k,v]
            }.inject([]) {|r,x| r + x}]
        else
          arg
        end
      end

    end
  end
end
