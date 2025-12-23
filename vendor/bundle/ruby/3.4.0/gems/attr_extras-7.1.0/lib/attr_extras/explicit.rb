require "attr_extras/version"
require "attr_extras/attr_initialize"
require "attr_extras/attr_value"
require "attr_extras/attr_query"
require "attr_extras/attr_implement"
require "attr_extras/utils"

module AttrExtras
  # To avoid masking coding errors, we don't inherit from StandardError (which would be implicitly rescued). Forgetting to define a requisite method isn't just some runtime error.
  class MethodNotImplementedError < Exception; end

  def self.mixin
    self::Mixin
  end

  # Separate module so that mixing in the methods doesn't also mix in constants:
  # http://thepugautomatic.com/2014/02/private-api/
  module Mixin
    def attr_initialize(*names, &block)
      AttrInitialize.new(self, names, block).apply
    end

    def attr_private(*names)
      # Avoid warnings: https://github.com/barsoom/attr_extras/pull/31
      return unless names && names.any?

      attr_reader(*names)
      private(*names)
    end

    def attr_value(*names)
      AttrValue.new(self, *names).apply
    end

    def pattr_initialize(*names, &block)
      attr_initialize(*names, &block)
      attr_private(*Utils.flat_names(names))
    end

    alias_method :attr_private_initialize, :pattr_initialize

    def vattr_initialize(*names, &block)
      attr_initialize(*names, &block)
      attr_value(*Utils.flat_names(names))
    end

    alias_method :attr_value_initialize, :vattr_initialize

    def rattr_initialize(*names, &block)
      attr_initialize(*names, &block)
      attr_reader(*Utils.flat_names(names))
    end

    alias_method :attr_reader_initialize, :rattr_initialize

    def aattr_initialize(*names, &block)
      attr_initialize(*names, &block)
      attr_accessor(*Utils.flat_names(names))
    end

    alias_method :attr_accessor_initialize, :aattr_initialize

    def static_facade(method_name_or_names, *names, &block)
      if names.any? { |name| name.is_a?(Array) }
        Array(method_name_or_names).each do |method_name|
          define_singleton_method(method_name) do |*args, **opts, &block|
            new(*args, **opts).public_send(method_name, &block)
          end
        end
      else
        Array(method_name_or_names).each do |method_name|
          define_singleton_method(method_name) do |*args, &block|
            new(*args).public_send(method_name, &block)
          end
        end
      end

      pattr_initialize(*names, &block)
    end

    def method_object(*names, &block)
      static_facade :call, *names, &block
    end

    def attr_query(*names)
      AttrQuery.define_with_suffix(self, "", *names)
    end

    def attr_id_query(*names)
      AttrQuery.define_with_suffix(self, "_id", *names)
    end

    def attr_implement(*names)
      AttrImplement.new(self, names).apply
    end

    def cattr_implement(*names)
      AttrImplement.new(self.singleton_class, names).apply
    end
  end
end
