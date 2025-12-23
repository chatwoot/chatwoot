# frozen_string_literal: true

require 'json'

module Rack
  class MiniProfiler
    module TimerStruct
      # A base class for timing structures
      class Base

        def initialize(attrs = {})
          @attributes = attrs
        end

        def attributes
          @attributes ||= {}
        end

        def [](name)
          attributes[name]
        end

        def []=(name, val)
          attributes[name] = val
        end

        def to_json(*a)
          # this does could take in an option hash, but the only interesting there is max_nesting.
          #   if this becomes an option we could increase
          ::JSON.generate(@attributes, max_nesting: 100)
        end

        def as_json(options = nil)
          @attributes.as_json(options)
        end
      end
    end
  end
end
