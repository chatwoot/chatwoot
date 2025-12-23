# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicated instance (or singleton) method
      # definitions.
      #
      # @example
      #
      #   # bad
      #   def foo
      #     1
      #   end
      #
      #   def foo
      #     2
      #   end
      #
      #   # bad
      #   def foo
      #     1
      #   end
      #
      #   alias foo bar
      #
      #   # good
      #   def foo
      #     1
      #   end
      #
      #   def bar
      #     2
      #   end
      #
      #   # good
      #   def foo
      #     1
      #   end
      #
      #   alias bar foo
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #
      #   # good
      #   def foo
      #     1
      #   end
      #
      #   delegate :foo, to: :bar
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #
      #   # bad
      #   def foo
      #     1
      #   end
      #
      #   delegate :foo, to: :bar
      #
      #   # good
      #   def foo
      #     1
      #   end
      #
      #   delegate :baz, to: :bar
      class DuplicateMethods < Base
        MSG = 'Method `%<method>s` is defined at both %<defined>s and %<current>s.'
        RESTRICT_ON_SEND = %i[alias_method attr_reader attr_writer attr_accessor attr
                              delegate].freeze

        def initialize(config = nil, options = nil)
          super
          @definitions = {}
          @scopes = Hash.new { |hash, key| hash[key] = [] }
        end

        def on_def(node)
          # if a method definition is inside an if, it is very likely
          # that a different definition is used depending on platform, etc.
          return if node.each_ancestor.any?(&:if_type?)

          found_instance_method(node, node.method_name)
        end

        def on_defs(node)
          return if node.each_ancestor.any?(&:if_type?)

          if node.receiver.const_type?
            _, const_name = *node.receiver
            check_const_receiver(node, node.method_name, const_name)
          elsif node.receiver.self_type?
            check_self_receiver(node, node.method_name)
          end
        end

        # @!method method_alias?(node)
        def_node_matcher :method_alias?, <<~PATTERN
          (alias (sym $_name) sym)
        PATTERN

        def on_alias(node)
          return unless (name = method_alias?(node))
          return if node.ancestors.any?(&:if_type?)

          found_instance_method(node, name)
        end

        # @!method alias_method?(node)
        def_node_matcher :alias_method?, <<~PATTERN
          (send nil? :alias_method (sym $_name) _)
        PATTERN

        # @!method delegate_method?(node)
        def_node_matcher :delegate_method?, <<~PATTERN
          (send nil? :delegate (sym $_)+ (hash _))
        PATTERN

        # @!method sym_name(node)
        def_node_matcher :sym_name, '(sym $_name)'

        def on_send(node) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          if (name = alias_method?(node))
            return if node.ancestors.any?(&:if_type?)

            found_instance_method(node, name)
          elsif (attr = node.attribute_accessor?)
            on_attr(node, *attr)
          elsif active_support_extensions_enabled? && (names = delegate_method?(node))
            return if node.ancestors.any?(&:if_type?)

            on_delegate(node, names)
          end
        end

        private

        def check_const_receiver(node, name, const_name)
          qualified = lookup_constant(node, const_name)
          return unless qualified

          found_method(node, "#{qualified}.#{name}")
        end

        def check_self_receiver(node, name)
          enclosing = node.parent_module_name
          return unless enclosing

          found_method(node, "#{enclosing}.#{name}")
        end

        def message_for_dup(node, method_name, key)
          format(MSG, method: method_name, defined: source_location(@definitions[key]),
                      current: source_location(node))
        end

        def on_delegate(node, method_names)
          method_names.each do |name|
            found_instance_method(node, name)
          end
        end

        def found_instance_method(node, name)
          return found_sclass_method(node, name) unless (scope = node.parent_module_name)

          # Humanize the scope
          scope = scope.sub(
            /(?:(?<name>.*)::)#<Class:\k<name>>|#<Class:(?<name>.*)>(?:::)?/,
            '\k<name>.'
          )
          scope << '#' unless scope.end_with?('.')

          found_method(node, "#{scope}#{name}")
        end

        def found_sclass_method(node, name)
          singleton_ancestor = node.each_ancestor.find(&:sclass_type?)
          return unless singleton_ancestor

          singleton_receiver_node = singleton_ancestor.children[0]
          return unless singleton_receiver_node.send_type?

          found_method(node, "#{singleton_receiver_node.method_name}.#{name}")
        end

        def found_method(node, method_name)
          key = method_key(node, method_name)
          scope = node.each_ancestor(:rescue, :ensure).first&.type

          if @definitions.key?(key)
            if scope && !@scopes[scope].include?(key)
              @definitions[key] = node
              @scopes[scope] << key
              return
            end

            message = message_for_dup(node, method_name, key)

            add_offense(location(node), message: message)
          else
            @definitions[key] = node
          end
        end

        def method_key(node, method_name)
          if (ancestor_def = node.each_ancestor(:any_def).first)
            "#{ancestor_def.method_name}.#{method_name}"
          else
            method_name
          end
        end

        def location(node)
          if node.any_def_type?
            node.loc.keyword.join(node.loc.name)
          else
            node.source_range
          end
        end

        def on_attr(node, attr_name, args)
          case attr_name
          when :attr
            writable = args.size == 2 && args.last.true_type?
            found_attr(node, [args.first], readable: true, writable: writable)
          when :attr_reader
            found_attr(node, args, readable: true)
          when :attr_writer
            found_attr(node, args, writable: true)
          when :attr_accessor
            found_attr(node, args, readable: true, writable: true)
          end
        end

        def found_attr(node, args, readable: false, writable: false)
          args.each do |arg|
            name = sym_name(arg)
            next unless name

            found_instance_method(node, name) if readable
            found_instance_method(node, "#{name}=") if writable
          end
        end

        def lookup_constant(node, const_name)
          # this method is quite imperfect and can be fooled
          # to do much better, we would need to do global analysis of the whole
          # codebase
          node.each_ancestor(:class, :module, :casgn) do |ancestor|
            namespace, mod_name = *ancestor.defined_module
            loop do
              if mod_name == const_name
                return qualified_name(ancestor.parent_module_name, namespace, mod_name)
              end

              break if namespace.nil?

              namespace, mod_name = *namespace
            end
          end
        end

        def qualified_name(enclosing, namespace, mod_name)
          if enclosing != 'Object'
            if namespace
              "#{enclosing}::#{namespace.const_name}::#{mod_name}"
            else
              "#{enclosing}::#{mod_name}"
            end
          elsif namespace
            "#{namespace.const_name}::#{mod_name}"
          else
            mod_name
          end
        end

        def source_location(node)
          range = node.source_range
          path = smart_path(range.source_buffer.name)
          "#{path}:#{range.line}"
        end
      end
    end
  end
end
