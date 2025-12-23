require 'declarative/definitions'

module Representable
  autoload :Option, 'representable/option'

  # Stores Definitions from ::property. It preserves the adding order (1.9+).
  # Same-named properties get overridden, just like in a Hash.
  #
  # Overwrite definition_class if you need a custom Definition object (helpful when using
  # representable in other gems).
  class Config < ::Declarative::Definitions
    def initialize(*)
      super
      @wrap = nil
    end

    def remove(name)
      delete(name.to_s)
    end

    def options # FIXME: this is not inherited.
      @options ||= {}
    end

    def wrap=(value)
      value = value.to_s if value.is_a?(Symbol)
      @wrap = ::Representable::Option(value)
    end

    # Computes the wrap string or returns false.
    def wrap_for(represented, options = {}, &block)
      return unless @wrap

      value = @wrap.(exec_context: represented, keyword_arguments: options.to_hash)

      return value if value != true

      infer_name_for(represented.class.name)
    end

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end
