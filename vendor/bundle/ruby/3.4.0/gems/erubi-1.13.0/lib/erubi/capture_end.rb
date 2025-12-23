# frozen_string_literal: true

require 'erubi'

module Erubi
  # An engine class that supports capturing blocks via the <tt><%|=</tt> and <tt><%|==</tt> tags,
  # explicitly ending the captures using <tt><%|</tt> end <tt>%></tt> blocks.
  class CaptureEndEngine < Engine
    # Initializes the engine.  Accepts the same arguments as ::Erubi::Engine, and these
    # additional options:
    # :escape_capture :: Whether to make <tt><%|=</tt> escape by default, and <tt><%|==</tt> not escape by default,
    #                    defaults to the same value as :escape.
    # :yield_returns_buffer :: Whether to have <tt><%|</tt> tags insert the buffer as an expression, so that
    #                          <tt><%| end %></tt> tags will have the buffer be the last expression inside
    #                          the block, and therefore have the buffer be returned by the yield
    #                          expression.  Normally the buffer will be returned anyway, but there
    #                          are cases where the last expression will not be the buffer,
    #                          and therefore a different object will be returned.
    def initialize(input, properties={})
      properties = Hash[properties]
      escape = properties.fetch(:escape){properties.fetch(:escape_html, false)}
      @escape_capture = properties.fetch(:escape_capture, escape)
      @yield_returns_buffer = properties.fetch(:yield_returns_buffer, false)
      @bufval = properties[:bufval] ||= '::String.new'
      @bufstack = '__erubi_stack'
      properties[:regexp] ||= /<%(\|?={1,2}|-|\#|%|\|)?(.*?)([-=])?%>([ \t]*\r?\n)?/m
      super
    end

    private

    # Handle the <%|= and <%|== tags
    def handle(indicator, code, tailch, rspace, lspace)
      case indicator
      when '|=', '|=='
        rspace = nil if tailch && !tailch.empty?
        add_text(lspace) if lspace
        escape_capture = !((indicator == '|=') ^ @escape_capture)
        terminate_expression
        @src << "begin; (#{@bufstack} ||= []) << #{@bufvar}; #{@bufvar} = #{@bufval}; #{@bufstack}.last << #{@escapefunc if escape_capture}((" << code
        @buffer_on_stack = false
        add_text(rspace) if rspace
      when '|'
        rspace = nil if tailch && !tailch.empty?
        add_text(lspace) if lspace
        if @yield_returns_buffer
          terminate_expression
          @src << " #{@bufvar}; "
        end
        @src << code << ")).to_s; ensure; #{@bufvar} = #{@bufstack}.pop; end;"
        @buffer_on_stack = false
        add_text(rspace) if rspace
      else
        super
      end
    end
  end
end
