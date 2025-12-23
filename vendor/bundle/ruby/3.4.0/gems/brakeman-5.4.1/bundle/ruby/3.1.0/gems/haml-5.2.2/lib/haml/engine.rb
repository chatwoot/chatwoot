# frozen_string_literal: true

require 'forwardable'

require 'haml/parser'
require 'haml/compiler'
require 'haml/options'
require 'haml/helpers'
require 'haml/buffer'
require 'haml/filters'
require 'haml/error'
require 'haml/temple_engine'

module Haml
  # This is the frontend for using Haml programmatically.
  # It can be directly used by the user by creating a
  # new instance and calling \{#render} to render the template.
  # For example:
  #
  #     template = File.read('templates/really_cool_template.haml')
  #     haml_engine = Haml::Engine.new(template)
  #     output = haml_engine.render
  #     puts output
  class Engine
    extend Forwardable
    include Haml::Util

    # The Haml::Options instance.
    # See {file:REFERENCE.md#options the Haml options documentation}.
    #
    # @return Haml::Options
    attr_accessor :options

    # The indentation used in the Haml document,
    # or `nil` if the indentation is ambiguous
    # (for example, for a single-level document).
    #
    # @return [String]
    attr_accessor :indentation

    # Tilt currently depends on these moved methods, provide a stable API
    def_delegators :compiler, :precompiled, :precompiled_method_return_value

    def options_for_buffer
      @options.for_buffer
    end

    # Precompiles the Haml template.
    #
    # @param template [String] The Haml template
    # @param options [{Symbol => Object}] An options hash;
    #   see {file:REFERENCE.md#options the Haml options documentation}
    # @raise [Haml::Error] if there's a Haml syntax error in the template
    def initialize(template, options = {})
      # Reflect changes of `Haml::Options.defaults` to `Haml::TempleEngine` options, but `#initialize_encoding`
      # should be run against the arguemnt `options[:encoding]` for backward compatibility with old `Haml::Engine`.
      options = Options.defaults.dup.tap { |o| o.delete(:encoding) }.merge!(options)
      @options = Options.new(options)

      @template = check_haml_encoding(template) do |msg, line|
        raise Haml::Error.new(msg, line)
      end

      @temple_engine = TempleEngine.new(options)
      @temple_engine.compile(@template)
    end

    # Deprecated API for backword compatibility
    def compiler
      @temple_engine
    end

    # Processes the template and returns the result as a string.
    #
    # `scope` is the context in which the template is evaluated.
    # If it's a `Binding`, Haml uses it as the second argument to `Kernel#eval`;
    # otherwise, Haml just uses its `#instance_eval` context.
    #
    # Note that Haml modifies the evaluation context
    # (either the scope object or the `self` object of the scope binding).
    # It extends {Haml::Helpers}, and various instance variables are set
    # (all prefixed with `haml_`).
    # For example:
    #
    #     s = "foobar"
    #     Haml::Engine.new("%p= upcase").render(s) #=> "<p>FOOBAR</p>"
    #
    #     # s now extends Haml::Helpers
    #     s.respond_to?(:html_attrs) #=> true
    #
    # `locals` is a hash of local variables to make available to the template.
    # For example:
    #
    #     Haml::Engine.new("%p= foo").render(Object.new, :foo => "Hello, world!") #=> "<p>Hello, world!</p>"
    #
    # If a block is passed to render,
    # that block is run when `yield` is called
    # within the template.
    #
    # Due to some Ruby quirks,
    # if `scope` is a `Binding` object and a block is given,
    # the evaluation context may not be quite what the user expects.
    # In particular, it's equivalent to passing `eval("self", scope)` as `scope`.
    # This won't have an effect in most cases,
    # but if you're relying on local variables defined in the context of `scope`,
    # they won't work.
    #
    # @param scope [Binding, Object] The context in which the template is evaluated
    # @param locals [{Symbol => Object}] Local variables that will be made available
    #   to the template
    # @param block [#to_proc] A block that can be yielded to within the template
    # @return [String] The rendered template
    def render(scope = Object.new, locals = {}, &block)
      parent = scope.instance_variable_defined?(:@haml_buffer) ? scope.instance_variable_get(:@haml_buffer) : nil
      buffer = Haml::Buffer.new(parent, @options.for_buffer)

      if scope.is_a?(Binding)
        scope_object = eval("self", scope)
        scope = scope_object.instance_eval{binding} if block_given?
      else
        scope_object = scope
        scope = scope_object.instance_eval{binding}
      end

      set_locals(locals.merge(:_hamlout => buffer, :_erbout => buffer.buffer), scope, scope_object)

      scope_object.extend(Haml::Helpers)
      scope_object.instance_variable_set(:@haml_buffer, buffer)
      begin
        eval(@temple_engine.precompiled_with_return_value, scope, @options.filename, @options.line)
      rescue ::SyntaxError => e
        raise SyntaxError, e.message
      end
    ensure
      # Get rid of the current buffer
      scope_object.instance_variable_set(:@haml_buffer, buffer.upper) if buffer
    end
    alias_method :to_html, :render

    # Returns a proc that, when called,
    # renders the template and returns the result as a string.
    #
    # `scope` works the same as it does for render.
    #
    # The first argument of the returned proc is a hash of local variable names to values.
    # However, due to an unfortunate Ruby quirk,
    # the local variables which can be assigned must be pre-declared.
    # This is done with the `local_names` argument.
    # For example:
    #
    #     # This works
    #     Haml::Engine.new("%p= foo").render_proc(Object.new, :foo).call :foo => "Hello!"
    #       #=> "<p>Hello!</p>"
    #
    #     # This doesn't
    #     Haml::Engine.new("%p= foo").render_proc.call :foo => "Hello!"
    #       #=> NameError: undefined local variable or method `foo'
    #
    # The proc doesn't take a block; any yields in the template will fail.
    #
    # @param scope [Binding, Object] The context in which the template is evaluated
    # @param local_names [Array<Symbol>] The names of the locals that can be passed to the proc
    # @return [Proc] The proc that will run the template
    def render_proc(scope = Object.new, *local_names)
      if scope.is_a?(Binding)
        scope_object = eval("self", scope)
      else
        scope_object = scope
        scope = scope_object.instance_eval{binding}
      end

      begin
        str = @temple_engine.precompiled_with_ambles(local_names)
        eval(
          "Proc.new { |*_haml_locals| _haml_locals = _haml_locals[0] || {}; #{str}}\n",
          scope,
          @options.filename,
          @options.line
        )
      rescue ::SyntaxError => e
        raise SyntaxError, e.message
      end
    end

    # Defines a method on `object` with the given name
    # that renders the template and returns the result as a string.
    #
    # If `object` is a class or module,
    # the method will instead be defined as an instance method.
    # For example:
    #
    #     t = Time.now
    #     Haml::Engine.new("%p\n  Today's date is\n  .date= self.to_s").def_method(t, :render)
    #     t.render #=> "<p>\n  Today's date is\n  <div class='date'>Fri Nov 23 18:28:29 -0800 2007</div>\n</p>\n"
    #
    #     Haml::Engine.new(".upcased= upcase").def_method(String, :upcased_div)
    #     "foobar".upcased_div #=> "<div class='upcased'>FOOBAR</div>\n"
    #
    # The first argument of the defined method is a hash of local variable names to values.
    # However, due to an unfortunate Ruby quirk,
    # the local variables which can be assigned must be pre-declared.
    # This is done with the `local_names` argument.
    # For example:
    #
    #     # This works
    #     obj = Object.new
    #     Haml::Engine.new("%p= foo").def_method(obj, :render, :foo)
    #     obj.render(:foo => "Hello!") #=> "<p>Hello!</p>"
    #
    #     # This doesn't
    #     obj = Object.new
    #     Haml::Engine.new("%p= foo").def_method(obj, :render)
    #     obj.render(:foo => "Hello!") #=> NameError: undefined local variable or method `foo'
    #
    # Note that Haml modifies the evaluation context
    # (either the scope object or the `self` object of the scope binding).
    # It extends {Haml::Helpers}, and various instance variables are set
    # (all prefixed with `haml_`).
    #
    # @param object [Object, Module] The object on which to define the method
    # @param name [String, Symbol] The name of the method to define
    # @param local_names [Array<Symbol>] The names of the locals that can be passed to the proc
    def def_method(object, name, *local_names)
      method = object.is_a?(Module) ? :module_eval : :instance_eval

      object.send(method, "def #{name}(_haml_locals = {}); #{@temple_engine.precompiled_with_ambles(local_names)}; end",
                  @options.filename, @options.line)
    end

    private

    def set_locals(locals, scope, scope_object)
      scope_object.instance_variable_set :@_haml_locals, locals
      set_locals = locals.keys.map { |k| "#{k} = @_haml_locals[#{k.inspect}]" }.join("\n")
      eval(set_locals, scope)
    end
  end
end
