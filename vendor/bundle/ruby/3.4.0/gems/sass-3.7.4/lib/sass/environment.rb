require 'set'

module Sass
  # The abstract base class for lexical environments for SassScript.
  class BaseEnvironment
    class << self
      # Note: when updating this,
      # update sass/yard/inherited_hash.rb as well.
      def inherited_hash_accessor(name)
        inherited_hash_reader(name)
        inherited_hash_writer(name)
      end

      def inherited_hash_reader(name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(name)
            _#{name}(name.tr('_', '-'))
          end

          def _#{name}(name)
            (@#{name}s && @#{name}s[name]) || @parent && @parent._#{name}(name)
          end
          protected :_#{name}

          def is_#{name}_global?(name)
            return !@parent if @#{name}s && @#{name}s.has_key?(name)
            @parent && @parent.is_#{name}_global?(name)
          end
        RUBY
      end

      def inherited_hash_writer(name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def set_#{name}(name, value)
            name = name.tr('_', '-')
            @#{name}s[name] = value unless try_set_#{name}(name, value)
          end

          def try_set_#{name}(name, value)
            @#{name}s ||= {}
            if @#{name}s.include?(name)
              @#{name}s[name] = value
              true
            elsif @parent && !@parent.global?
              @parent.try_set_#{name}(name, value)
            else
              false
            end
          end
          protected :try_set_#{name}

          def set_local_#{name}(name, value)
            @#{name}s ||= {}
            @#{name}s[name.tr('_', '-')] = value
          end

          def set_global_#{name}(name, value)
            global_env.set_#{name}(name, value)
          end
        RUBY
      end
    end

    # The options passed to the Sass Engine.
    attr_reader :options

    attr_writer :caller
    attr_writer :content
    attr_writer :selector

    # variable
    # Script::Value
    inherited_hash_reader :var

    # mixin
    # Sass::Callable
    inherited_hash_reader :mixin

    # function
    # Sass::Callable
    inherited_hash_reader :function

    # @param options [{Symbol => Object}] The options hash. See
    #   {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    # @param parent [Environment] See \{#parent}
    def initialize(parent = nil, options = nil)
      @parent = parent
      @options = options || (parent && parent.options) || {}
      @stack = @parent.nil? ? Sass::Stack.new : nil
      @caller = nil
      @content = nil
      @filename = nil
      @functions = nil
      @mixins = nil
      @selector = nil
      @vars = nil
    end

    # Returns whether this is the global environment.
    #
    # @return [Boolean]
    def global?
      @parent.nil?
    end

    # The environment of the caller of this environment's mixin or function.
    # @return {Environment?}
    def caller
      @caller || (@parent && @parent.caller)
    end

    # The content passed to this environment. This is naturally only set
    # for mixin body environments with content passed in.
    #
    # @return {[Array<Sass::Tree::Node>, Environment]?} The content nodes and
    #   the lexical environment of the content block.
    def content
      @content || (@parent && @parent.content)
    end

    # The selector for the current CSS rule, or nil if there is no
    # current CSS rule.
    #
    # @return [Selector::CommaSequence?] The current selector, with any
    #   nesting fully resolved.
    def selector
      @selector || (@caller && @caller.selector) || (@parent && @parent.selector)
    end

    # The top-level Environment object.
    #
    # @return [Environment]
    def global_env
      @global_env ||= global? ? self : @parent.global_env
    end

    # The import/mixin stack.
    #
    # @return [Sass::Stack]
    def stack
      @stack || global_env.stack
    end
  end

  # The lexical environment for SassScript.
  # This keeps track of variable, mixin, and function definitions.
  #
  # A new environment is created for each level of Sass nesting.
  # This allows variables to be lexically scoped.
  # The new environment refers to the environment in the upper scope,
  # so it has access to variables defined in enclosing scopes,
  # but new variables are defined locally.
  #
  # Environment also keeps track of the {Engine} options
  # so that they can be made available to {Sass::Script::Functions}.
  class Environment < BaseEnvironment
    # The enclosing environment,
    # or nil if this is the global environment.
    #
    # @return [Environment]
    attr_reader :parent

    # variable
    # Script::Value
    inherited_hash_writer :var

    # mixin
    # Sass::Callable
    inherited_hash_writer :mixin

    # function
    # Sass::Callable
    inherited_hash_writer :function
  end

  # A read-only wrapper for a lexical environment for SassScript.
  class ReadOnlyEnvironment < BaseEnvironment
    def initialize(parent = nil, options = nil)
      super
      @content_cached = nil
    end
    # The read-only environment of the caller of this environment's mixin or function.
    #
    # @see BaseEnvironment#caller
    # @return {ReadOnlyEnvironment}
    def caller
      return @caller if @caller
      env = super
      @caller ||= env.is_a?(ReadOnlyEnvironment) ? env : ReadOnlyEnvironment.new(env, env.options)
    end

    # The content passed to this environment. If the content's environment isn't already
    # read-only, it's made read-only.
    #
    # @see BaseEnvironment#content
    #
    # @return {[Array<Sass::Tree::Node>, ReadOnlyEnvironment]?} The content nodes and
    #   the lexical environment of the content block.
    #   Returns `nil` when there is no content in this environment.
    def content
      # Return the cached content from a previous invocation if any
      return @content if @content_cached
      # get the content with a read-write environment from the superclass
      read_write_content = super
      if read_write_content
        tree, env = read_write_content
        # make the content's environment read-only
        if env && !env.is_a?(ReadOnlyEnvironment)
          env = ReadOnlyEnvironment.new(env, env.options)
        end
        @content_cached = true
        @content = [tree, env]
      else
        @content_cached = true
        @content = nil
      end
    end
  end

  # An environment that can write to in-scope global variables, but doesn't
  # create new variables in the global scope. Useful for top-level control
  # directives.
  class SemiGlobalEnvironment < Environment
    def try_set_var(name, value)
      @vars ||= {}
      if @vars.include?(name)
        @vars[name] = value
        true
      elsif @parent
        @parent.try_set_var(name, value)
      else
        false
      end
    end
  end
end
