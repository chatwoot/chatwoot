# frozen_string_literal: true

module Aws
  module Json
    module JSONEngine
      class << self
        def load(json)
          JSON.parse(json)
        rescue JSON::ParserError => e
          raise ParseError.new(e)
        end

        def dump(value)
          JSON.dump(value)
        end
      end
    end
  end
end
