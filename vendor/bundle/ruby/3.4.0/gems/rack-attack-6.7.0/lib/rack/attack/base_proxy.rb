# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    class BaseProxy < SimpleDelegator
      class << self
        def proxies
          @@proxies ||= []
        end

        def inherited(klass)
          proxies << klass
        end

        def lookup(store)
          proxies.find { |proxy| proxy.handle?(store) }
        end

        def handle?(_store)
          raise NotImplementedError
        end
      end
    end
  end
end
