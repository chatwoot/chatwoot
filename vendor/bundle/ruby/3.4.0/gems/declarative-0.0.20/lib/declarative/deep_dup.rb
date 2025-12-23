# frozen_string_literal: true

module Declarative
  module DeepDup
    def self.call(args)
      case args
      when Array
        Array[*dup_items(args)]
      when ::Hash
        ::Hash[dup_items(args)]
      else
        args

      end
    end

    def self.dup_items(arr)
      arr.to_a.collect { |v| call(v) }
    end
  end
end
