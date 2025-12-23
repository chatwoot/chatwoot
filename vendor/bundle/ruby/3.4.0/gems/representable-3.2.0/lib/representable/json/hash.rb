require 'representable/json'
require 'representable/hash_methods'

module Representable::JSON
  # "Lonely Hash" support.
  module Hash
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        include Representable::JSON
        include Representable::HashMethods
        property(:_self, hash: true)
      end
    end


    module ClassMethods
      def values(options, &block)
        hash(:_self, options, &block)
      end
    end
  end
end
