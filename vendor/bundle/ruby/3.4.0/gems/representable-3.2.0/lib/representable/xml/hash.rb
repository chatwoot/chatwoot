require 'representable/xml'
require 'representable/hash_methods'

module Representable::XML
  module AttributeHash
    include Representable::XML
    include Representable::HashMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        property(:_self, hash: true, use_attributes: true)
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options.merge!(:use_attributes => true)
      end
    end

    def create_representation_with(doc, options, format)
      bin = representable_bindings_for(format, options).first
      bin.write(doc, super, options)
    end
  end

  module Hash
    include Representable::XML
    include HashMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        property(:_self, {:hash => true})
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options
      end
    end
  end
end
