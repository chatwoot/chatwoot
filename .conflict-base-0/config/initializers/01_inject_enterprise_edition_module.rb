# frozen_string_literal: true

# original Authors: Gitlab
# https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/0_inject_enterprise_edition_module.rb
#

### Ref: https://medium.com/@leo_hetsch/ruby-modules-include-vs-prepend-vs-extend-f09837a5b073
# Ancestors chain : it holds a list of constant names which are its ancestors
#  example, by calling ancestors on the String class,
#  String.ancestors => [String, Comparable, Object, PP::ObjectMixin, Kernel, BasicObject]
#
# Include: Ruby will insert the module into the ancestors chain of the class, just after its superclass
# ancestor chain : [OriginalClass, IncludedModule, ...]
#
# Extend: class will actually import the module methods as class methods
#
# Prepend: Ruby will look into the module methods before looking into the class.
# ancestor chain : [PrependedModule, OriginalClass, ...]
########

require 'active_support/inflector'

module InjectEnterpriseEditionModule
  def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
    each_extension_for(constant_name, namespace) do |constant|
      prepend_module(constant, with_descendants)
    end
  end

  def extend_mod_with(constant_name, namespace: Object)
    # rubocop:disable Performance/MethodObjectAsBlock
    each_extension_for(
      constant_name,
      namespace,
      &method(:extend)
    )
    # rubocop:enable Performance/MethodObjectAsBlock
  end

  def include_mod_with(constant_name, namespace: Object)
    # rubocop:disable Performance/MethodObjectAsBlock
    each_extension_for(
      constant_name,
      namespace,
      &method(:include)
    )
    # rubocop:enable Performance/MethodObjectAsBlock
  end

  def prepend_mod(with_descendants: false)
    prepend_mod_with(name, with_descendants: with_descendants)
  end

  def extend_mod
    extend_mod_with(name)
  end

  def include_mod
    include_mod_with(name)
  end

  private

  def prepend_module(mod, with_descendants)
    prepend(mod)

    descendants.each { |descendant| descendant.prepend(mod) } if with_descendants
  end

  def each_extension_for(constant_name, namespace)
    ChatwootApp.extensions.each do |extension_name|
      extension_namespace =
        const_get_maybe_false(namespace, extension_name.camelize)

      extension_module =
        const_get_maybe_false(extension_namespace, constant_name)

      yield(extension_module) if extension_module
    end
  end

  def const_get_maybe_false(mod, name)
    mod&.const_defined?(name, false) && mod&.const_get(name, false)
  end
end

Module.prepend(InjectEnterpriseEditionModule)
