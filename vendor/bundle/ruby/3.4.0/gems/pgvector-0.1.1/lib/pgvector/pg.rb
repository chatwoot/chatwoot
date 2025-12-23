require "pg"

module Pgvector
  module PG
    def self.register_vector(registry)
      registry.register_type(0, "vector", nil, TextDecoder::Vector)
      registry.register_type(1, "vector", nil, BinaryDecoder::Vector)
    end

    module BinaryDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          dim, unused = string[0, 4].unpack("nn")
          raise "expected unused to be 0" if unused != 0
          string[4..-1].unpack("g#{dim}")
        end
      end
    end

    module TextDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          string[1..-2].split(",").map(&:to_f)
        end
      end
    end
  end
end
