# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks for class and module names with
      # an underscore in them.
      #
      # `AllowedNames` config takes an array of permitted names.
      # Its default value is `['module_parent']`.
      # These names can be full class/module names or part of the name.
      # eg. Adding `my_class` to the `AllowedNames` config will allow names like
      # `my_class`, `my_class::User`, `App::my_class`, `App::my_class::User`, etc.
      #
      # @example
      #   # bad
      #   class My_Class
      #   end
      #   module My_Module
      #   end
      #
      #   # good
      #   class MyClass
      #   end
      #   module MyModule
      #   end
      #   class module_parent::MyModule
      #   end
      class ClassAndModuleCamelCase < Base
        MSG = 'Use CamelCase for classes and modules.'

        def on_class(node)
          return unless node.loc.name.source.include?('_')

          allowed = /#{cop_config['AllowedNames'].join('|')}/
          name = node.loc.name.source.gsub(allowed, '')
          return unless name.include?('_')

          add_offense(node.loc.name)
        end
        alias on_module on_class
      end
    end
  end
end
