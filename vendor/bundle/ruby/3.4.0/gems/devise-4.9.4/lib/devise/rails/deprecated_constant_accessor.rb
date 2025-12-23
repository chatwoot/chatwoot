# frozen_string_literal: true

begin
  require 'active_support/deprecation/constant_accessor'

  module Devise
    DeprecatedConstantAccessor = ActiveSupport::Deprecation::DeprecatedConstantAccessor #:nodoc:
  end
rescue LoadError

  # Copy of constant deprecation module from Rails / Active Support version 6, so we can use it
  # with Rails <= 5.0 versions. This can be removed once we support only Rails 5.1 or greater.
  module Devise
    module DeprecatedConstantAccessor #:nodoc:
      def self.included(base)
        require "active_support/inflector/methods"

        extension = Module.new do
          def const_missing(missing_const_name)
            if class_variable_defined?(:@@_deprecated_constants)
              if (replacement = class_variable_get(:@@_deprecated_constants)[missing_const_name.to_s])
                replacement[:deprecator].warn(replacement[:message] || "#{name}::#{missing_const_name} is deprecated! Use #{replacement[:new]} instead.", Rails::VERSION::MAJOR == 4 ? caller : caller_locations)
                return ActiveSupport::Inflector.constantize(replacement[:new].to_s)
              end
            end
            super
          end

          def deprecate_constant(const_name, new_constant, message: nil, deprecator: Devise.deprecator)
            class_variable_set(:@@_deprecated_constants, {}) unless class_variable_defined?(:@@_deprecated_constants)
            class_variable_get(:@@_deprecated_constants)[const_name.to_s] = { new: new_constant, message: message, deprecator: deprecator }
          end
        end
        base.singleton_class.prepend extension
      end
    end
  end

end
