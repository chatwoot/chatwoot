# frozen_string_literal: true

module Erubi
  VERSION = '1.13.0'

  # :nocov:
  if RUBY_VERSION >= '1.9'
    RANGE_FIRST = 0
    RANGE_LAST = -1
  else
    RANGE_FIRST = 0..0
    RANGE_LAST = -1..-1
  end

  MATCH_METHOD = RUBY_VERSION >= '2.4' ? :match? : :match
  SKIP_DEFINED_FOR_INSTANCE_VARIABLE = RUBY_VERSION > '3'
  FREEZE_TEMPLATE_LITERALS = !eval("''").frozen? && RUBY_VERSION >= '2.1'
  # :nocov:

  begin
    require 'erb/escape'
    define_method(:h, ERB::Escape.instance_method(:html_escape))
  # :nocov:
  rescue LoadError
    begin
      require 'cgi/escape'
      unless CGI.respond_to?(:escapeHTML) # work around for JRuby 9.1
        CGI = Object.new
        CGI.extend(defined?(::CGI::Escape) ? ::CGI::Escape : ::CGI::Util)
      end
      # Escape characters with their HTML/XML equivalents.
      def h(value)
        CGI.escapeHTML(value.to_s)
      end
    rescue LoadError
      ESCAPE_TABLE = {'&' => '&amp;'.freeze, '<' => '&lt;'.freeze, '>' => '&gt;'.freeze, '"' => '&quot;'.freeze, "'" => '&#39;'.freeze}.freeze
      if RUBY_VERSION >= '1.9'
        def h(value)
          value.to_s.gsub(/[&<>"']/, ESCAPE_TABLE)
        end
      else
        def h(value)
          value.to_s.gsub(/[&<>"']/){|s| ESCAPE_TABLE[s]}
        end
      end
    end
  end
  # :nocov:
  module_function :h

  class Engine
    # The default regular expression used for scanning.
    DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>([ \t]*\r?\n)?/m
    
    # The frozen ruby source code generated from the template, which can be evaled.
    attr_reader :src

    # The filename of the template, if one was given.
    attr_reader :filename

    # The variable name used for the buffer variable.
    attr_reader :bufvar

    # Initialize a new Erubi::Engine.  Options:
    # +:bufval+ :: The value to use for the buffer variable, as a string (default <tt>'::String.new'</tt>).
    # +:bufvar+ :: The variable name to use for the buffer variable, as a string.
    # +:chain_appends+ :: Whether to chain <tt><<</t> calls to the buffer variable. Offers better
    #                     performance, but can cause issues when the buffer variable is reassigned during
    #                     template rendering (default +false+).
    # +:ensure+ :: Wrap the template in a begin/ensure block restoring the previous value of bufvar.
    # +:escapefunc+ :: The function to use for escaping, as a string (default: <tt>'::Erubi.h'</tt>).
    # +:escape+ :: Whether to make <tt><%=</tt> escape by default, and <tt><%==</tt> not escape by default.
    # +:escape_html+ :: Same as +:escape+, with lower priority.
    # +:filename+ :: The filename for the template.
    # +:freeze+ :: Whether to enable add a <tt>frozen_string_literal: true</tt> magic comment at the top of
    #              the resulting source code.  Note this may cause problems if you are wrapping the resulting
    #              source code in other code, because the magic comment only has an effect at the beginning of
    #              the file, and having the magic comment later in the file can trigger warnings.
    # +:freeze_template_literals+ :: Whether to suffix all literal strings for template code with <tt>.freeze</tt>
    #                                (default: +true+ on Ruby 2.1+, +false+ on Ruby 2.0 and older).
    #                                Can be set to +false+ on Ruby 2.3+ when frozen string literals are enabled
    #                                in order to improve performance.
    # +:literal_prefix+ :: The prefix to output when using escaped tag delimiters (default <tt>'<%'</tt>).
    # +:literal_postfix+ :: The postfix to output when using escaped tag delimiters (default <tt>'%>'</tt>).
    # +:outvar+ :: Same as +:bufvar+, with lower priority.
    # +:postamble+ :: The postamble for the template, by default returns the resulting source code.
    # +:preamble+ :: The preamble for the template, by default initializes the buffer variable.
    # +:regexp+ :: The regexp to use for scanning.
    # +:src+ :: The initial value to use for the source code, an empty string by default.
    # +:trim+ :: Whether to trim leading and trailing whitespace, true by default.
    def initialize(input, properties={})
      @escape = escape = properties.fetch(:escape){properties.fetch(:escape_html, false)}
      trim       = properties[:trim] != false
      @filename  = properties[:filename]
      @bufvar = bufvar = properties[:bufvar] || properties[:outvar] || "_buf"
      bufval = properties[:bufval] || '::String.new'
      regexp = properties[:regexp] || DEFAULT_REGEXP
      literal_prefix = properties[:literal_prefix] || '<%'
      literal_postfix = properties[:literal_postfix] || '%>'
      preamble   = properties[:preamble] || "#{bufvar} = #{bufval};"
      postamble  = properties[:postamble] || "#{bufvar}.to_s\n"
      @chain_appends = properties[:chain_appends]
      @text_end = if properties.fetch(:freeze_template_literals, FREEZE_TEMPLATE_LITERALS)
        "'.freeze"
      else
        "'"
      end

      @buffer_on_stack = false
      @src = src = properties[:src] || String.new
      src << "# frozen_string_literal: true\n" if properties[:freeze]
      if properties[:ensure]
        src << "begin; __original_outvar = #{bufvar}"
        if SKIP_DEFINED_FOR_INSTANCE_VARIABLE && /\A@[^@]/ =~ bufvar
          src << "; "
        else
          src << " if defined?(#{bufvar}); "
        end
      end

      unless @escapefunc = properties[:escapefunc]
        if escape
          @escapefunc = '__erubi.h'
          src << "__erubi = ::Erubi; "
        else
          @escapefunc = '::Erubi.h'
        end
      end

      src << preamble

      pos = 0
      is_bol = true
      input.scan(regexp) do |indicator, code, tailch, rspace|
        match = Regexp.last_match
        len  = match.begin(0) - pos
        text = input[pos, len]
        pos  = match.end(0)
        ch   = indicator ? indicator[RANGE_FIRST] : nil

        lspace = nil

        unless ch == '='
          if text.empty?
            lspace = "" if is_bol
          elsif text[RANGE_LAST] == "\n"
            lspace = ""
          else
            rindex = text.rindex("\n")
            if rindex
              range = rindex+1..-1
              s = text[range]
              if /\A[ \t]*\z/.send(MATCH_METHOD, s)
                lspace = s
                text[range] = ''
              end
            else
              if is_bol && /\A[ \t]*\z/.send(MATCH_METHOD, text)
                lspace = text
                text = ''
              end
            end
          end
        end

        is_bol = rspace
        add_text(text)
        case ch
        when '='
          rspace = nil if tailch && !tailch.empty?
          add_expression(indicator, code)
          add_text(rspace) if rspace
        when nil, '-'
          if trim && lspace && rspace
            add_code("#{lspace}#{code}#{rspace}")
          else
            add_text(lspace) if lspace
            add_code(code)
            add_text(rspace) if rspace
          end
        when '#'
          n = code.count("\n") + (rspace ? 1 : 0)
          if trim && lspace && rspace
            add_code("\n" * n)
          else
            add_text(lspace) if lspace
            add_code("\n" * n)
            add_text(rspace) if rspace
          end
        when '%'
          add_text("#{lspace}#{literal_prefix}#{code}#{tailch}#{literal_postfix}#{rspace}")
        else
          handle(indicator, code, tailch, rspace, lspace)
        end
      end
      rest = pos == 0 ? input : input[pos..-1]
      add_text(rest)

      src << "\n" unless src[RANGE_LAST] == "\n"
      add_postamble(postamble)
      src << "; ensure\n  " << bufvar << " = __original_outvar\nend\n" if properties[:ensure]
      src.freeze
      freeze
    end

    private

    # Add raw text to the template.  Modifies argument if argument is mutable as a memory optimization.
    # Must be called with a string, cannot be called with nil (Rails's subclass depends on it).
    def add_text(text)
      return if text.empty?

      if text.frozen?
        text = text.gsub(/['\\]/, '\\\\\&')
      else
        text.gsub!(/['\\]/, '\\\\\&')
      end

      with_buffer{@src << " << '" << text << @text_end}
    end

    # Add ruby code to the template
    def add_code(code)
      terminate_expression
      @src << code
      @src << ';' unless code[RANGE_LAST] == "\n"
      @buffer_on_stack = false
    end

    # Add the given ruby expression result to the template,
    # escaping it based on the indicator given and escape flag.
    def add_expression(indicator, code)
      if ((indicator == '=') ^ @escape)
        add_expression_result(code)
      else
        add_expression_result_escaped(code)
      end
    end

    # Add the result of Ruby expression to the template
    def add_expression_result(code)
      with_buffer{@src << ' << (' << code << ').to_s'}
    end

    # Add the escaped result of Ruby expression to the template
    def add_expression_result_escaped(code)
      with_buffer{@src << ' << ' << @escapefunc << '((' << code << '))'}
    end

    # Add the given postamble to the src.  Can be overridden in subclasses
    # to make additional changes to src that depend on the current state.
    def add_postamble(postamble)
      terminate_expression
      @src << postamble
    end

    # Raise an exception, as the base engine class does not support handling other indicators.
    def handle(indicator, code, tailch, rspace, lspace)
      raise ArgumentError, "Invalid indicator: #{indicator}"
    end

    # Make sure the buffer variable is the target of the next append
    # before yielding to the block. Mark that the buffer is the target
    # of the next append after the block executes.
    #
    # This method should only be called if the block will result in
    # code where << will append to the bufvar.
    def with_buffer
      if @chain_appends
        unless @buffer_on_stack
          @src << '; ' << @bufvar
        end
        yield
        @buffer_on_stack = true
      else
        @src << ' ' << @bufvar
        yield
        @src << ';'
      end
    end

    # Make sure that any current expression has been terminated.
    # The default is to terminate all expressions, but when
    # the chain_appends option is used, expressions may not be
    # terminated.
    def terminate_expression
      @src << '; ' if @chain_appends
    end
  end
end
