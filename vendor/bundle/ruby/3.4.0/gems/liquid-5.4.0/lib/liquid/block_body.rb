# frozen_string_literal: true

require 'English'

module Liquid
  class BlockBody
    LiquidTagToken      = /\A\s*(#{TagName})\s*(.*?)\z/o
    FullToken           = /\A#{TagStart}#{WhitespaceControl}?(\s*)(#{TagName})(\s*)(.*?)#{WhitespaceControl}?#{TagEnd}\z/om
    ContentOfVariable   = /\A#{VariableStart}#{WhitespaceControl}?(.*?)#{WhitespaceControl}?#{VariableEnd}\z/om
    WhitespaceOrNothing = /\A\s*\z/
    TAGSTART            = "{%"
    VARSTART            = "{{"

    attr_reader :nodelist

    def initialize
      @nodelist = []
      @blank    = true
    end

    def parse(tokenizer, parse_context, &block)
      raise FrozenError, "can't modify frozen Liquid::BlockBody" if frozen?

      parse_context.line_number = tokenizer.line_number

      if tokenizer.for_liquid_tag
        parse_for_liquid_tag(tokenizer, parse_context, &block)
      else
        parse_for_document(tokenizer, parse_context, &block)
      end
    end

    def freeze
      @nodelist.freeze
      super
    end

    private def parse_for_liquid_tag(tokenizer, parse_context)
      while (token = tokenizer.shift)
        unless token.empty? || token.match?(WhitespaceOrNothing)
          unless token =~ LiquidTagToken
            # line isn't empty but didn't match tag syntax, yield and let the
            # caller raise a syntax error
            return yield token, token
          end
          tag_name = Regexp.last_match(1)
          markup   = Regexp.last_match(2)
          unless (tag = registered_tags[tag_name])
            # end parsing if we reach an unknown tag and let the caller decide
            # determine how to proceed
            return yield tag_name, markup
          end
          new_tag = tag.parse(tag_name, markup, tokenizer, parse_context)
          @blank &&= new_tag.blank?
          @nodelist << new_tag
        end
        parse_context.line_number = tokenizer.line_number
      end

      yield nil, nil
    end

    # @api private
    def self.unknown_tag_in_liquid_tag(tag, parse_context)
      Block.raise_unknown_tag(tag, 'liquid', '%}', parse_context)
    end

    # @api private
    def self.raise_missing_tag_terminator(token, parse_context)
      raise SyntaxError, parse_context.locale.t("errors.syntax.tag_termination", token: token, tag_end: TagEnd.inspect)
    end

    # @api private
    def self.raise_missing_variable_terminator(token, parse_context)
      raise SyntaxError, parse_context.locale.t("errors.syntax.variable_termination", token: token, tag_end: VariableEnd.inspect)
    end

    # @api private
    def self.render_node(context, output, node)
      node.render_to_output_buffer(context, output)
    rescue => exc
      blank_tag = !node.instance_of?(Variable) && node.blank?
      rescue_render_node(context, output, node.line_number, exc, blank_tag)
    end

    # @api private
    def self.rescue_render_node(context, output, line_number, exc, blank_tag)
      case exc
      when MemoryError
        raise
      when UndefinedVariable, UndefinedDropMethod, UndefinedFilter
        context.handle_error(exc, line_number)
      else
        error_message = context.handle_error(exc, line_number)
        unless blank_tag # conditional for backwards compatibility
          output << error_message
        end
      end
    end

    private def parse_liquid_tag(markup, parse_context)
      liquid_tag_tokenizer = parse_context.new_tokenizer(
        markup, start_line_number: parse_context.line_number, for_liquid_tag: true
      )
      parse_for_liquid_tag(liquid_tag_tokenizer, parse_context) do |end_tag_name, _end_tag_markup|
        if end_tag_name
          BlockBody.unknown_tag_in_liquid_tag(end_tag_name, parse_context)
        end
      end
    end

    private def parse_for_document(tokenizer, parse_context)
      while (token = tokenizer.shift)
        next if token.empty?
        case
        when token.start_with?(TAGSTART)
          whitespace_handler(token, parse_context)
          unless token =~ FullToken
            BlockBody.raise_missing_tag_terminator(token, parse_context)
          end
          tag_name = Regexp.last_match(2)
          markup   = Regexp.last_match(4)

          if parse_context.line_number
            # newlines inside the tag should increase the line number,
            # particularly important for multiline {% liquid %} tags
            parse_context.line_number += Regexp.last_match(1).count("\n") + Regexp.last_match(3).count("\n")
          end

          if tag_name == 'liquid'
            parse_liquid_tag(markup, parse_context)
            next
          end

          unless (tag = registered_tags[tag_name])
            # end parsing if we reach an unknown tag and let the caller decide
            # determine how to proceed
            return yield tag_name, markup
          end
          new_tag = tag.parse(tag_name, markup, tokenizer, parse_context)
          @blank &&= new_tag.blank?
          @nodelist << new_tag
        when token.start_with?(VARSTART)
          whitespace_handler(token, parse_context)
          @nodelist << create_variable(token, parse_context)
          @blank = false
        else
          if parse_context.trim_whitespace
            token.lstrip!
          end
          parse_context.trim_whitespace = false
          @nodelist << token
          @blank &&= token.match?(WhitespaceOrNothing)
        end
        parse_context.line_number = tokenizer.line_number
      end

      yield nil, nil
    end

    def whitespace_handler(token, parse_context)
      if token[2] == WhitespaceControl
        previous_token = @nodelist.last
        if previous_token.is_a?(String)
          first_byte = previous_token.getbyte(0)
          previous_token.rstrip!
          if previous_token.empty? && parse_context[:bug_compatible_whitespace_trimming] && first_byte
            previous_token << first_byte
          end
        end
      end
      parse_context.trim_whitespace = (token[-3] == WhitespaceControl)
    end

    def blank?
      @blank
    end

    # Remove blank strings in the block body for a control flow tag (e.g. `if`, `for`, `case`, `unless`)
    # with a blank body.
    #
    # For example, in a conditional assignment like the following
    #
    # ```
    # {% if size > max_size %}
    #   {% assign size = max_size %}
    # {% endif %}
    # ```
    #
    # we assume the intention wasn't to output the blank spaces in the `if` tag's block body, so this method
    # will remove them to reduce the render output size.
    #
    # Note that it is now preferred to use the `liquid` tag for this use case.
    def remove_blank_strings
      raise "remove_blank_strings only support being called on a blank block body" unless @blank
      @nodelist.reject! { |node| node.instance_of?(String) }
    end

    def render(context)
      render_to_output_buffer(context, +'')
    end

    def render_to_output_buffer(context, output)
      freeze unless frozen?

      context.resource_limits.increment_render_score(@nodelist.length)

      idx = 0
      while (node = @nodelist[idx])
        if node.instance_of?(String)
          output << node
        else
          render_node(context, output, node)
          # If we get an Interrupt that means the block must stop processing. An
          # Interrupt is any command that stops block execution such as {% break %}
          # or {% continue %}. These tags may also occur through Block or Include tags.
          break if context.interrupt? # might have happened in a for-block
        end
        idx += 1

        context.resource_limits.increment_write_score(output)
      end

      output
    end

    private

    def render_node(context, output, node)
      BlockBody.render_node(context, output, node)
    end

    def create_variable(token, parse_context)
      if token =~ ContentOfVariable
        markup = Regexp.last_match(1)
        return Variable.new(markup, parse_context)
      end
      BlockBody.raise_missing_variable_terminator(token, parse_context)
    end

    # @deprecated Use {.raise_missing_tag_terminator} instead
    def raise_missing_tag_terminator(token, parse_context)
      BlockBody.raise_missing_tag_terminator(token, parse_context)
    end

    # @deprecated Use {.raise_missing_variable_terminator} instead
    def raise_missing_variable_terminator(token, parse_context)
      BlockBody.raise_missing_variable_terminator(token, parse_context)
    end

    def registered_tags
      Template.tags
    end
  end
end
