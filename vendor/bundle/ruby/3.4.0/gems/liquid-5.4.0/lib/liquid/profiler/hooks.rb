# frozen_string_literal: true

module Liquid
  module BlockBodyProfilingHook
    def render_node(context, output, node)
      if (profiler = context.profiler)
        profiler.profile_node(context.template_name, code: node.raw, line_number: node.line_number) do
          super
        end
      else
        super
      end
    end
  end
  BlockBody.prepend(BlockBodyProfilingHook)

  module DocumentProfilingHook
    def render_to_output_buffer(context, output)
      return super unless context.profiler
      context.profiler.profile(context.template_name) { super }
    end
  end
  Document.prepend(DocumentProfilingHook)

  module ContextProfilingHook
    attr_accessor :profiler

    def new_isolated_subcontext
      new_context = super
      new_context.profiler = profiler
      new_context
    end
  end
  Context.prepend(ContextProfilingHook)
end
