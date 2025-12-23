# frozen_string_literal: true

module RubyLLM
  class Schema
    class Validator
      # Node states for DFS-based topological sort
      WHITE = :white  # No mark (unvisited)
      GRAY = :gray    # Temporary mark (currently being processed)
      BLACK = :black  # Permanent mark (completely processed)

      def initialize(schema_class)
        @schema_class = schema_class
      end

      def validate!
        validate_circular_references!
        # Future validations can be added here
      end

      def valid?
        validate!
        true
      rescue ValidationError
        false
      end

      private

      def validate_circular_references!
        definitions = @schema_class.definitions
        return if definitions.empty?

        # Initialize all nodes as WHITE (no mark)
        marks = Hash.new { WHITE }

        # Visit each unmarked node
        definitions.each_key do |node|
          visit(node, definitions, marks) if marks[node] == WHITE
        end
      end

      # DFS visit function
      def visit(node, definitions, marks)
        # If node has a permanent mark, return
        return if marks[node] == BLACK

        # If node has a temporary mark, we found a cycle
        if marks[node] == GRAY
          raise ValidationError, "Circular reference detected involving '#{node}'"
        end

        # Mark node with temporary mark
        marks[node] = GRAY

        # Visit all adjacent nodes (dependencies)
        definition = definitions[node]
        if definition && definition[:properties]
          definition[:properties].each_value do |property|
            references = extract_references(property)
            references.each do |adjacent_node|
              visit(adjacent_node, definitions, marks)
            end
          end
        end

        # Mark node with permanent mark
        marks[node] = BLACK
      end

      def extract_references(property)
        references = []

        case property
        when Hash
          if property["$ref"]
            # Extract definition name from reference like "#/$defs/user"
            ref_name = property["$ref"].split("/").last&.to_sym
            references << ref_name if ref_name
          else
            # Recursively check nested properties
            property.each_value do |value|
              references.concat(extract_references(value))
            end
          end
        when Array
          property.each do |item|
            references.concat(extract_references(item))
          end
        end

        references
      end
    end
  end
end
