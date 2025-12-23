# frozen_string_literal: true

require "set"
require "stringio"

module CommonMarker
  class Renderer
    attr_accessor :in_tight, :warnings, :in_plain

    def initialize(options: :DEFAULT, extensions: [])
      @opts = Config.process_options(options, :render)
      @stream = StringIO.new(+"")
      @need_blocksep = false
      @warnings = Set.new([])
      @in_tight = false
      @in_plain = false
      @tagfilter = extensions.include?(:tagfilter)
    end

    def out(*args)
      args.each do |arg|
        case arg
        when :children
          @node.each { |child| out(child) }
        when Array
          arg.each { |x| render(x) }
        when Node
          render(arg)
        else
          @stream.write(arg)
        end
      end
    end

    def render(node)
      @node = node
      if node.type == :document
        document(node)
        @stream.string
      elsif @in_plain && node.type != :text && node.type != :softbreak
        node.each { |child| render(child) }
      else
        begin
          send(node.type, node)
        rescue NoMethodError => e
          @warnings.add("WARNING: #{node.type} not implemented.")
          raise e
        end
      end
    end

    def document(_node)
      out(:children)
    end

    def code_block(node)
      code_block(node)
    end

    def reference_def(_node); end

    def cr
      return if @stream.string.empty? || @stream.string[-1] == "\n"

      out("\n")
    end

    def blocksep
      out("\n")
    end

    def containersep
      cr unless @in_tight
    end

    def block
      cr
      yield
      cr
    end

    def container(starter, ender)
      out(starter)
      yield
      out(ender)
    end

    def plain
      old_in_plain = @in_plain
      @in_plain = true
      yield
      @in_plain = old_in_plain
    end

    private

    def escape_href(str)
      @node.html_escape_href(str)
    end

    def escape_html(str)
      @node.html_escape_html(str)
    end

    def tagfilter(str)
      if @tagfilter
        str.gsub(
          %r{
            <
            (
            title|textarea|style|xmp|iframe|
            noembed|noframes|script|plaintext
            )
            (?=\s|>|/>)
          }xi,
          '&lt;\1',
        )
      else
        str
      end
    end

    def sourcepos(node)
      return "" unless option_enabled?(:SOURCEPOS)

      s = node.sourcepos
      " data-sourcepos=\"#{s[:start_line]}:#{s[:start_column]}-" \
        "#{s[:end_line]}:#{s[:end_column]}\""
    end

    def option_enabled?(opt)
      (@opts & CommonMarker::Config::OPTS.dig(:render, opt)) != 0
    end
  end
end
