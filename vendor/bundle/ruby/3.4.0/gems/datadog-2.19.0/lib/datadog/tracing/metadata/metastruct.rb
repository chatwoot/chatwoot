# frozen_string_literal: true

require 'forwardable'

module Datadog
  module Tracing
    module Metadata
      # This class is a data structure that is used to store
      # complex metadata, such as an array of objects.
      #
      # It is serialized to MessagePack format when sent to the agent.
      class Metastruct
        extend Forwardable

        def_delegators :@metastruct, :[], :[]=, :to_h

        def initialize
          @metastruct = {}
        end

        def to_msgpack(packer = nil)
          # JRuby doesn't pass the packer
          packer ||= MessagePack::Packer.new

          packer.write(@metastruct.transform_values(&:to_msgpack))
        end

        def pretty_print(q)
          q.seplist @metastruct.each do |key, value|
            q.text "#{key} => #{value}"
          end
        end
      end
    end
  end
end
