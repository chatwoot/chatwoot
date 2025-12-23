# frozen_string_literal: true

module Liquid
  class Ifchanged < Block
    def render_to_output_buffer(context, output)
      block_output = +''
      super(context, block_output)

      if block_output != context.registers[:ifchanged]
        context.registers[:ifchanged] = block_output
        output << block_output
      end

      output
    end
  end

  Template.register_tag('ifchanged', Ifchanged)
end
