# frozen_string_literal: true

module Twitty
  module Errors
    class MissingParams < StandardError
      def initialize(msg = 'Params are missing')
        super
      end
    end
  end
end
