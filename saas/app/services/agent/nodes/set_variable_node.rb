# frozen_string_literal: true

# Sets a variable in the run context. The value can be a static string or a Liquid expression.
class Agent::Nodes::SetVariableNode < BaseNode
  protected

  def process
    name = data['variable_name']
    expression = data['expression'] || ''

    value = render_template(expression)
    context.set_variable(name, value)

    { output: { variable: name, value: value } }
  end
end
