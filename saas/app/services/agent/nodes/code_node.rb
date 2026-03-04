# frozen_string_literal: true

# Executes a Liquid template as a "code" node.
# The rendered output is stored in a context variable.
# This is intentionally limited to Liquid (no arbitrary Ruby/JS execution).
class Agent::Nodes::CodeNode < Agent::Nodes::BaseNode
  MAX_OUTPUT_SIZE = 10_000

  protected

  def process
    code = data['code'] || ''
    output_var = data['output_variable'] || 'code_result'

    result = render_template(code).truncate(MAX_OUTPUT_SIZE)
    context.set_variable(output_var, result)

    { output: { result_length: result.length, language: data['language'] || 'liquid' } }
  end
end
