require 'rubocop'

# Enforces having only one class definition per file
# Excludes common Ruby patterns:
# - Nested Scope classes (Pundit pattern)
# - Single-line exception classes inheriting from StandardError or other exceptions
# - Nested classes within exception/error hierarchies
class RuboCop::Cop::Style::OneClassPerFile < RuboCop::Cop::Base
  MSG = 'Define only one class per file.'.freeze

  def on_new_investigation
    return unless processed_source.ast

    class_nodes = processed_source.ast.each_node(:class).to_a
    return if class_nodes.size <= 1

    class_nodes[1..].each do |node|
      next if allowed_nested_class?(node)

      add_offense(node, message: MSG)
    end
  end

  private

  def allowed_nested_class?(node)
    # Allow nested Scope classes (Pundit pattern)
    return true if scope_class?(node)

    # Allow nested Request classes (Rack::Attack pattern)
    return true if rack_attack_request_class?(node)

    # Allow exception classes (single-line or multi-line)
    return true if exception_class?(node)

    # Allow classes within CustomExceptions modules
    return true if in_custom_exceptions_module?(node)

    # Allow common nested patterns: Builder, Factory, Result, Response, Params, etc.
    return true if common_nested_pattern?(node)

    false
  end

  def scope_class?(node)
    class_name = node.identifier.source
    class_name == 'Scope'
  end

  def rack_attack_request_class?(node)
    class_name = node.identifier.source
    return false unless class_name == 'Request'

    # Check if we're inside a Rack::Attack class
    node.each_ancestor(:class).any? do |ancestor|
      ancestor.identifier.source.include?('Rack::Attack')
    end
  end

  def exception_class?(node)
    # Check if the class inherits from StandardError or ends with 'Error'
    return false unless node.parent_class

    parent_class = node.parent_class.source
    parent_class.include?('Error') || parent_class.include?('StandardError')
  end

  def in_custom_exceptions_module?(node)
    # Check if any parent node is a module containing 'CustomExceptions'
    node.each_ancestor(:module).any? do |ancestor|
      ancestor.identifier.source.include?('CustomExceptions')
    end
  end

  def common_nested_pattern?(node)
    class_name = node.identifier.source

    # Common nested class patterns in Ruby/Rails
    nested_patterns = %w[Builder Factory Result Response Params Config Configuration
                         Context Query Form Validator Serializer Presenter Decorator
                         Command Handler]

    # Check if class name ends with any of these patterns
    nested_patterns.any? { |pattern| class_name.end_with?(pattern) }
  end
end
