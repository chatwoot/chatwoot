# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category iteration
  # @liquid_name for
  # @liquid_summary
  #   Renders an expression for every item in an array.
  # @liquid_description
  #   You can do a maximum of 50 iterations with a `for` loop. If you need to iterate over more than 50 items, then use the
  #   [`paginate` tag](/api/liquid/tags#paginate) to split the items over multiple pages.
  #
  #   > Tip:
  #   > Every `for` loop has an associated [`forloop` object](/api/liquid/objects#forloop) with information about the loop.
  # @liquid_syntax
  #   {% for variable in array %}
  #     expression
  #   {% endfor %}
  # @liquid_syntax_keyword variable The current item in the array.
  # @liquid_syntax_keyword array The array to iterate over.
  # @liquid_syntax_keyword expression The expression to render for each iteration.
  # @liquid_optional_param limit [number] The number of iterations to perform.
  # @liquid_optional_param offset [number] The 1-based index to start iterating at.
  # @liquid_optional_param range [untyped] A custom numeric range to iterate over.
  # @liquid_optional_param reversed [untyped] Iterate in reverse order.
  class For < Block
    Syntax = /\A(#{VariableSegment}+)\s+in\s+(#{QuotedFragment}+)\s*(reversed)?/o

    attr_reader :collection_name, :variable_name, :limit, :from

    def initialize(tag_name, markup, options)
      super
      @from = @limit = nil
      parse_with_selected_parser(markup)
      @for_block = new_body
      @else_block = nil
    end

    def parse(tokens)
      if parse_body(@for_block, tokens)
        parse_body(@else_block, tokens)
      end
      if blank?
        @else_block&.remove_blank_strings
        @for_block.remove_blank_strings
      end
      @else_block&.freeze
      @for_block.freeze
    end

    def nodelist
      @else_block ? [@for_block, @else_block] : [@for_block]
    end

    def unknown_tag(tag, markup, tokens)
      return super unless tag == 'else'
      @else_block = new_body
    end

    def render_to_output_buffer(context, output)
      segment = collection_segment(context)

      if segment.empty?
        render_else(context, output)
      else
        render_segment(context, output, segment)
      end

      output
    end

    protected

    def lax_parse(markup)
      if markup =~ Syntax
        @variable_name   = Regexp.last_match(1)
        collection_name  = Regexp.last_match(2)
        @reversed        = !!Regexp.last_match(3)
        @name            = "#{@variable_name}-#{collection_name}"
        @collection_name = parse_expression(collection_name)
        markup.scan(TagAttributes) do |key, value|
          set_attribute(key, value)
        end
      else
        raise SyntaxError, options[:locale].t("errors.syntax.for")
      end
    end

    def strict_parse(markup)
      p = Parser.new(markup)
      @variable_name = p.consume(:id)
      raise SyntaxError, options[:locale].t("errors.syntax.for_invalid_in") unless p.id?('in')

      collection_name  = p.expression
      @collection_name = parse_expression(collection_name)

      @name     = "#{@variable_name}-#{collection_name}"
      @reversed = p.id?('reversed')

      while p.look(:id) && p.look(:colon, 1)
        unless (attribute = p.id?('limit') || p.id?('offset'))
          raise SyntaxError, options[:locale].t("errors.syntax.for_invalid_attribute")
        end
        p.consume
        set_attribute(attribute, p.expression)
      end
      p.consume(:end_of_string)
    end

    private

    def collection_segment(context)
      offsets = context.registers[:for] ||= {}

      from = if @from == :continue
        offsets[@name].to_i
      else
        from_value = context.evaluate(@from)
        if from_value.nil?
          0
        else
          Utils.to_integer(from_value)
        end
      end

      collection = context.evaluate(@collection_name)
      collection = collection.to_a if collection.is_a?(Range)

      limit_value = context.evaluate(@limit)
      to = if limit_value.nil?
        nil
      else
        Utils.to_integer(limit_value) + from
      end

      segment = Utils.slice_collection(collection, from, to)
      segment.reverse! if @reversed

      offsets[@name] = from + segment.length

      segment
    end

    def render_segment(context, output, segment)
      for_stack = context.registers[:for_stack] ||= []
      length    = segment.length

      context.stack do
        loop_vars = Liquid::ForloopDrop.new(@name, length, for_stack[-1])

        for_stack.push(loop_vars)

        begin
          context['forloop'] = loop_vars

          segment.each do |item|
            context[@variable_name] = item
            @for_block.render_to_output_buffer(context, output)
            loop_vars.send(:increment!)

            # Handle any interrupts if they exist.
            next unless context.interrupt?
            interrupt = context.pop_interrupt
            break if interrupt.is_a?(BreakInterrupt)
            next if interrupt.is_a?(ContinueInterrupt)
          end
        ensure
          for_stack.pop
        end
      end

      output
    end

    def set_attribute(key, expr)
      case key
      when 'offset'
        @from = if expr == 'continue'
          Usage.increment('for_offset_continue')
          :continue
        else
          parse_expression(expr)
        end
      when 'limit'
        @limit = parse_expression(expr)
      end
    end

    def render_else(context, output)
      if @else_block
        @else_block.render_to_output_buffer(context, output)
      else
        output
      end
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        (super + [@node.limit, @node.from, @node.collection_name]).compact
      end
    end
  end

  Template.register_tag('for', For)
end
