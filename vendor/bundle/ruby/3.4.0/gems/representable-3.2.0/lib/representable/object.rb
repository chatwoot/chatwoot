require 'representable'
require 'representable/object/binding'

module Representable
  module Object
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        register_feature Representable::Object
      end
    end


    module ClassMethods
      def collection_representer_class
        Collection
      end
    end

    def from_object(data, options={}, binding_builder=Binding)
      update_properties_from(data, options, binding_builder)
    end

    def to_object(options={}, binding_builder=Binding)
      create_representation_with(nil, options, binding_builder)
    end
  end
end
