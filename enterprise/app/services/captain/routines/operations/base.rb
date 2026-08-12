class Captain::Routines::Operations::Base
  # Operations expose only their DSL contract until the routine runner introduces execution behavior.
  class << self
    attr_reader :operation_name, :effect, :approval, :description, :arguments, :required_arguments

    def configure(name:, **definition)
      @operation_name = name
      @effect = definition.fetch(:effect)
      @approval = definition.fetch(:approval)
      @description = definition.fetch(:description)
      @arguments = definition.fetch(:arguments).freeze
      @required_arguments = definition.fetch(:required, []).map(&:to_s).freeze
    end

    def definition
      {
        kind: kind,
        effect: effect,
        approval: approval,
        description: description,
        arguments: arguments,
        required: required_arguments
      }
    end
  end
end
