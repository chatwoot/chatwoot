# frozen_string_literal: true

require "tilt"

module Haml
  # The module containing the default Haml filters,
  # as well as the base module, {Haml::Filters::Base}.
  #
  # @see Haml::Filters::Base
  module Filters

    extend self

    # @return [{String => Haml::Filters::Base}] a hash mapping filter names to
    #   classes.
    attr_reader :defined
    @defined = {}

    # Loads an external template engine from
    # [Tilt](https://github.com/rtomayko/tilt) as a filter. This method is used
    # internally by Haml to set up filters for Sass, SCSS, Less, Coffeescript,
    # and others. It's left public to make it easy for developers to add their
    # own Tilt-based filters if they choose.
    #
    # @return [Module] The generated filter.
    # @param [Hash] options Options for generating the filter module.
    # @option options [Boolean] :precompiled Whether the filter should be
    #   precompiled. Erb, Nokogiri and Builder use this, for example.
    # @option options [Class] :template_class The Tilt template class to use,
    #   in the event it can't be inferred from an extension.
    # @option options [String] :extension The extension associated with the
    #   content, for example "markdown". This lets Tilt choose the preferred
    #   engine when there are more than one.
    # @option options [String,Array<String>] :alias Any aliases for the filter.
    #   For example, :coffee is also available as :coffeescript.
    # @option options [String] :extend The name of a module to extend when
    #   defining the filter. Defaults to "Plain". This allows filters such as
    #   Coffee to "inherit" from Javascript, wrapping its output in script tags.
    # @since 4.0
    def register_tilt_filter(name, options = {})
      if constants.map(&:to_s).include?(name.to_s)
        raise "#{name} filter already defined"
      end

      filter = const_set(name, Module.new)
      filter.extend const_get(options[:extend] || "Plain")
      filter.extend TiltFilter
      filter.extend PrecompiledTiltFilter if options.has_key? :precompiled

      if options.has_key? :template_class
        filter.template_class = options[:template_class]
      else
        filter.tilt_extension = options.fetch(:extension) { name.downcase }
      end

      # All ":coffeescript" as alias for ":coffee", etc.
      if options.has_key?(:alias)
        [options[:alias]].flatten.each {|x| Filters.defined[x.to_s] = filter}
      end
      filter
    end

    # Removes a filter from Haml. If the filter was removed, it returns
    # the Module that was removed upon success, or nil on failure. If you try
    # to redefine a filter, Haml will raise an error. Use this method first to
    # explicitly remove the filter before redefining it.
    # @return Module The filter module that has been removed
    # @since 4.0
    def remove_filter(name)
      defined.delete name.to_s.downcase
      if constants.map(&:to_s).include?(name.to_s)
        remove_const name.to_sym
      end
    end

    # The base module for Haml filters.
    # User-defined filters should be modules including this module.
    # The name of the filter is taken by downcasing the module name.
    # For instance, if the module is named `FooBar`, the filter will be `:foobar`.
    #
    # A user-defined filter should override either \{#render} or {\#compile}.
    # \{#render} is the most common.
    # It takes a string, the filter source,
    # and returns another string, the result of the filter.
    # For example, the following will define a filter named `:sass`:
    #
    #     module Haml::Filters::Sass
    #       include Haml::Filters::Base
    #
    #       def render(text)
    #         ::Sass::Engine.new(text).render
    #       end
    #     end
    #
    # For details on overriding \{#compile}, see its documentation.
    #
    # Note that filters overriding \{#render} automatically support `#{}`
    # for interpolating Ruby code.
    # Those overriding \{#compile} will need to add such support manually
    # if it's desired.
    module Base
      # This method is automatically called when {Base} is included in a module.
      # It automatically defines a filter
      # with the downcased name of that module.
      # For example, if the module is named `FooBar`, the filter will be `:foobar`.
      #
      # @param base [Module, Class] The module that this is included in
      def self.included(base)
        Filters.defined[base.name.split("::").last.downcase] = base
        base.extend(base)
      end

      # Takes the source text that should be passed to the filter
      # and returns the result of running the filter on that string.
      #
      # This should be overridden in most individual filter modules
      # to render text with the given filter.
      # If \{#compile} is overridden, however, \{#render} doesn't need to be.
      #
      # @param text [String] The source text for the filter to process
      # @return [String] The filtered result
      # @raise [Haml::Error] if it's not overridden
      def render(_text)
        raise Error.new("#{self.inspect}#render not defined!")
      end

      # Same as \{#render}, but takes a {Haml::Engine} options hash as well.
      # It's only safe to rely on options made available in {Haml::Engine#options\_for\_buffer}.
      #
      # @see #render
      # @param text [String] The source text for the filter to process
      # @return [String] The filtered result
      # @raise [Haml::Error] if it or \{#render} isn't overridden
      def render_with_options(text, _options)
        render(text)
      end

      # Same as \{#compile}, but requires the necessary files first.
      # *This is used by {Haml::Engine} and is not intended to be overridden or used elsewhere.*
      #
      # @see #compile
      def internal_compile(*args)
        compile(*args)
      end

      # This should be overridden when a filter needs to have access to the Haml
      # evaluation context. Rather than applying a filter to a string at
      # compile-time, \{#compile} uses the {Haml::Compiler} instance to compile
      # the string to Ruby code that will be executed in the context of the
      # active Haml template.
      #
      # Warning: the {Haml::Compiler} interface is neither well-documented
      # nor guaranteed to be stable.
      # If you want to make use of it, you'll probably need to look at the
      # source code and should test your filter when upgrading to new Haml
      # versions.
      #
      # @param compiler [Haml::Compiler] The compiler instance
      # @param text [String] The text of the filter
      # @raise [Haml::Error] if none of \{#compile}, \{#render}, and
      #   \{#render_with_options} are overridden
      def compile(compiler, text)
        filter = self
        compiler.instance_eval do
          if contains_interpolation?(text)
            return if options[:suppress_eval]

            escape = options[:escape_filter_interpolations]
            # `escape_filter_interpolations` defaults to `escape_html` if unset.
            escape = options[:escape_html] if escape.nil?

            text = unescape_interpolation(text, escape).gsub(/(\\+)n/) do |s|
              escapes = $1.size
              next s if escapes % 2 == 0
              "#{'\\' * (escapes - 1)}\n"
            end
            # We need to add a newline at the beginning to get the
            # filter lines to line up (since the Haml filter contains
            # a line that doesn't show up in the source, namely the
            # filter name). Then we need to escape the trailing
            # newline so that the whole filter block doesn't take up
            # too many.
            text = %[\n#{text.sub(/\n"\Z/, "\\n\"")}]
            push_script <<RUBY.rstrip, :escape_html => false
find_and_preserve(#{filter.inspect}.render_with_options(#{text}, _hamlout.options))
RUBY
            return
          end

          rendered = Haml::Helpers::find_and_preserve(filter.render_with_options(text.to_s, compiler.options), compiler.options[:preserve])
          push_text("#{rendered.rstrip}\n")
        end
      end
    end

    # Does not parse the filtered text.
    # This is useful for large blocks of text without HTML tags, when you don't
    # want lines starting with `.` or `-` to be parsed.
    module Plain
      include Base

      # @see Base#render
      def render(text); text; end
    end

    # Surrounds the filtered text with `<script>` and CDATA tags. Useful for
    # including inline Javascript.
    module Javascript
      include Base

      # @see Base#render_with_options
      def render_with_options(text, options)
        indent = options[:cdata] ? '    ' : '  ' # 4 or 2 spaces
        if options[:format] == :html5
          type = ''
        else
          type = " type=#{options[:attr_wrapper]}text/javascript#{options[:attr_wrapper]}"
        end

        text = text.rstrip
        text.gsub!("\n", "\n#{indent}")

        %!<script#{type}>\n#{"  //<![CDATA[\n" if options[:cdata]}#{indent}#{text}\n#{"  //]]>\n" if options[:cdata]}</script>!
      end
    end

    # Surrounds the filtered text with `<style>` and CDATA tags. Useful for
    # including inline CSS.
    module Css
      include Base

      # @see Base#render_with_options
      def render_with_options(text, options)
        indent = options[:cdata] ? '    ' : '  ' # 4 or 2 spaces
        if options[:format] == :html5
          type = ''
        else
          type = " type=#{options[:attr_wrapper]}text/css#{options[:attr_wrapper]}"
        end

        text = text.rstrip
        text.gsub!("\n", "\n#{indent}")

        %(<style#{type}>\n#{"  /*<![CDATA[*/\n" if options[:cdata]}#{indent}#{text}\n#{"  /*]]>*/\n" if options[:cdata]}</style>)
      end
    end

    # Surrounds the filtered text with CDATA tags.
    module Cdata
      include Base

      # @see Base#render
      def render(text)
        "<![CDATA[#{"\n#{text.rstrip}".gsub("\n", "\n    ")}\n]]>"
      end
    end

    # Works the same as {Plain}, but HTML-escapes the text before placing it in
    # the document.
    module Escaped
      include Base

      # @see Base#render
      def render(text)
        Haml::Helpers.html_escape text
      end
    end

    # Parses the filtered text with the normal Ruby interpreter. Creates an IO
    # object named `haml_io`, anything written to it is output into the Haml
    # document. In previous version this filter redirected any output to `$stdout`
    # to the Haml document, this was not threadsafe and has been removed, you
    # should use `haml_io` instead.
    #
    # Not available if the {file:REFERENCE.md#suppress_eval-option `:suppress_eval`}
    # option is set to true. The Ruby code is evaluated in the same context as
    # the Haml template.
    module Ruby
      include Base
      require 'stringio'

      # @see Base#compile
      def compile(compiler, text)
        return if compiler.options[:suppress_eval]
        compiler.instance_eval do
          push_silent "#{<<-FIRST.tr("\n", ';')}#{text}#{<<-LAST.tr("\n", ';')}"
            begin
              haml_io = StringIO.new(_hamlout.buffer, 'a')
          FIRST
            ensure
              haml_io.close
              haml_io = nil
            end
          LAST
        end
      end
    end

    # Inserts the filtered text into the template with whitespace preserved.
    # `preserve`d blocks of text aren't indented, and newlines are replaced with
    # the HTML escape code for newlines, to preserve nice-looking output.
    #
    # @see Haml::Helpers#preserve
    module Preserve
      include Base

      # @see Base#render
      def render(text)
        Haml::Helpers.preserve text
      end
    end

    # @private
    module TiltFilter
      extend self
      attr_accessor :tilt_extension, :options
      attr_writer :template_class

      def template_class
        (@template_class if defined? @template_class) or begin
          @template_class = Tilt["t.#{tilt_extension}"] or
            raise Error.new(Error.message(:cant_run_filter, tilt_extension))
        rescue LoadError => e
          dep = e.message.split('--').last.strip
          raise Error.new(Error.message(:gem_install_filter_deps, tilt_extension, dep))
        end
      end

      def self.extended(base)
        base.options = {}
        # There's a bug in 1.9.2 where the same parse tree cannot be shared
        # across several singleton classes -- this bug is fixed in 1.9.3.
        # We work around this by using a string eval instead of a block eval
        # so that a new parse tree is created for each singleton class.
        base.instance_eval %Q{
          include Base

          def render_with_options(text, compiler_options)
            text = template_class.new(nil, 1, options) {text}.render
            super(text, compiler_options)
          end
        }
      end
    end

    # @private
    module PrecompiledTiltFilter
      def precompiled(text)
        template_class.new(nil, 1, options) { text }.send(:precompiled, {}).first
      end

      def compile(compiler, text)
        return if compiler.options[:suppress_eval]
        compiler.send(:push_script, precompiled(text))
      end
    end

    # @!parse module Sass; end
    register_tilt_filter "Sass", :extend => "Css"

    # @!parse module Scss; end
    register_tilt_filter "Scss", :extend => "Css"

    # @!parse module Less; end
    register_tilt_filter "Less", :extend => "Css"

    # @!parse module Markdown; end
    register_tilt_filter "Markdown"

    # @!parse module Erb; end
    register_tilt_filter "Erb", :precompiled => true

    # @!parse module Coffee; end
    register_tilt_filter "Coffee", :alias => "coffeescript", :extend => "Javascript"

    # Parses the filtered text with ERB.
    # Not available if the {file:REFERENCE.md#suppress_eval-option
    # `:suppress_eval`} option is set to true. Embedded Ruby code is evaluated
    # in the same context as the Haml template.
    module Erb
      class << self
        def precompiled(text)
          #workaround for https://github.com/rtomayko/tilt/pull/183
          require 'erubis' if (defined?(::Erubis) && !defined?(::Erubis::Eruby))
          super.sub(/^#coding:.*?\n/, '')
        end
      end
    end
  end
end

# These filters have been demoted to Haml Contrib but are still included by
# default in Haml 4.0. Still, we rescue from load error if for some reason
# haml-contrib is not installed.
begin
  require "haml/filters/maruku"
  require "haml/filters/textile"
rescue LoadError
end
