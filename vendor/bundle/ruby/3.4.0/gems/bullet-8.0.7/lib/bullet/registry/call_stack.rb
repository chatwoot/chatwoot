# frozen_string_literal: true

module Bullet
  module Registry
    class CallStack < Base
      # remembers found association backtrace
      def add(key)
        @registry[key] ||= Thread.current.backtrace
      end
    end
  end
end
