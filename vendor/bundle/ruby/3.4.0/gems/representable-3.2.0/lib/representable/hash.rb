require 'representable'
require 'representable/hash/binding'

module Representable
  # The generic representer. Brings #to_hash and #from_hash to your object.
  # If you plan to write your own representer for a new media type, try to use this module (e.g., check how JSON reuses Hash's internal
  # architecture).
  module Hash
    autoload :Collection, 'representable/hash/collection'
    autoload :AllowSymbols, 'representable/hash/allow_symbols'

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods
        register_feature Representable::Hash
      end
    end

    module ClassMethods
      def format_engine
        Representable::Hash
      end

      def collection_representer_class
        Collection
      end
    end

    def from_hash(data, options={}, binding_builder=Binding)
      data = filter_wrap(data, options)

      update_properties_from(data, options, binding_builder)
    end

    def to_hash(options={}, binding_builder=Binding)
      hash = create_representation_with({}, options, binding_builder)

      return hash if options[:wrap] == false
      return hash unless (wrap = options[:wrap] || representation_wrap(options))

      {wrap => hash}
    end

    alias_method :render, :to_hash
    alias_method :parse, :from_hash

  private
    def filter_wrap(data, options)
      return data if options[:wrap] == false
      return data unless (wrap = options[:wrap] || representation_wrap(options))

      filter_wrap_for(data, wrap)
    end

    def filter_wrap_for(data, wrap)
      data[wrap.to_s] || {} # DISCUSS: don't initialize this more than once. # TODO: this should be done with #read.
    end
  end
end
