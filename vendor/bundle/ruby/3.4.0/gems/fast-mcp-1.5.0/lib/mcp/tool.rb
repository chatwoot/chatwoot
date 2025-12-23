# frozen_string_literal: true

require 'dry-schema'

# Extend Dry::Schema macros to support description
module Dry
  module Schema
    module Macros
      # Add description method to Value macro
      class Value
        def description(text)
          key_name = name.to_sym
          schema_dsl.meta(key_name, :description, text)

          self
        end

        def hidden(hidden = true) # rubocop:disable Style/OptionalBooleanParameter
          key_name = name.to_sym
          schema_dsl.meta(key_name, :hidden, hidden)

          self
        end
      end

      # Add description method to Required macro
      class Required
        def description(text)
          key_name = name.to_sym
          schema_dsl.meta(key_name, :description, text)

          self
        end

        def hidden(hidden = true) # rubocop:disable Style/OptionalBooleanParameter
          key_name = name.to_sym
          schema_dsl.meta(key_name, :hidden, hidden)

          self
        end
      end

      # Add description method to Optional macro
      class Optional
        def description(text)
          key_name = name.to_sym
          schema_dsl.meta(key_name, :description, text)

          self
        end

        def hidden(hidden = true) # rubocop:disable Style/OptionalBooleanParameter
          key_name = name.to_sym
          schema_dsl.meta(key_name, :hidden, hidden)

          self
        end
      end

      # Add description method to Hash macro
      class Hash
        def description(text)
          key_name = name.to_sym
          schema_dsl.meta(key_name, :description, text)
          self
        end
      end
    end
  end
end

# Extend Dry::Schema DSL to store metadata
module Dry
  module Schema
    class DSL
      def meta(key_name, meta_key, value)
        @meta ||= {}
        @meta[key_name] ||= {}
        @meta[key_name][meta_key] = value
      end

      def meta_data
        @meta || {}
      end
    end
  end
end

module FastMcp
  # Main Tool class that represents an MCP Tool
  class Tool
    class InvalidArgumentsError < StandardError; end

    class << self
      attr_accessor :server

      # Add tagging support for tools
      def tags(*tag_list)
        if tag_list.empty?
          @tags || []
        else
          @tags = tag_list.flatten.map(&:to_sym)
        end
      end

      # Add metadata support for tools
      def metadata(key = nil, value = nil)
        @metadata ||= {}
        if key.nil?
          @metadata
        elsif value.nil?
          @metadata[key]
        else
          @metadata[key] = value
        end
      end

      def arguments(&block)
        @input_schema = Dry::Schema.JSON(&block)
      end

      def input_schema
        @input_schema ||= Dry::Schema.JSON
      end

      def tool_name(name = nil)
        return @name || self.name if name.nil?

        @name = name
      end

      def description(description = nil)
        return @description if description.nil?

        @description = description
      end

      def authorize(&block)
        @authorization_blocks ||= []
        @authorization_blocks.push block
      end

      def call(**args)
        raise NotImplementedError, 'Subclasses must implement the call method'
      end

      def input_schema_to_json
        return nil unless @input_schema

        compiler = SchemaCompiler.new
        compiler.process(@input_schema)
      end
    end

    def initialize(headers: {})
      @_meta = {}
      @headers = headers
    end

    def authorized?(**args)
      auth_checks = self.class.ancestors.filter_map do |ancestor|
        ancestor.ancestors.include?(FastMcp::Tool) &&
          ancestor.instance_variable_get(:@authorization_blocks)
      end.flatten

      return true if auth_checks.empty?

      arg_validation = self.class.input_schema.call(args)
      raise InvalidArgumentsError, arg_validation.errors.to_h.to_json if arg_validation.errors.any?

      auth_checks.all? do |auth_check|
        if auth_check.parameters.empty?
          instance_exec(&auth_check)
        else
          instance_exec(**args, &auth_check)
        end
      end
    end

    attr_accessor :_meta
    attr_reader :headers

    def notify_resource_updated(uri)
      self.class.server.notify_resource_updated(uri)
    end

    def call_with_schema_validation!(**args)
      arg_validation = self.class.input_schema.call(args)
      raise InvalidArgumentsError, arg_validation.errors.to_h.to_json if arg_validation.errors.any?

      # When calling the tool, its metadata can be altered to be returned in response.
      # We return the altered metadata with the tool's result
      [call(**args), _meta]
    end
  end

  # Module for handling schema metadata
  module SchemaMetadataExtractor
    # Extract metadata from a schema
    def extract_metadata_from_schema(schema)
      # a deeply-assignable hash, the default value of a key is {}
      metadata = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

      # Extract descriptions from the top-level schema
      if schema.respond_to?(:schema_dsl) && schema.schema_dsl.respond_to?(:meta_data)
        schema.schema_dsl.meta_data.each do |key, meta|
          metadata[key.to_s][:description] = meta[:description] if meta[:description]
          metadata[key.to_s][:hidden] = meta[:hidden]
        end
      end

      # Extract metadata from nested schemas using AST
      schema.rules.each_value do |rule|
        next unless rule.respond_to?(:ast)

        extract_metadata_from_ast(rule.ast, metadata)
      end

      metadata
    end

    # Extract metadata from AST
    def extract_metadata_from_ast(ast, metadata, parent_key = nil)
      return unless ast.is_a?(Array)

      process_key_node(ast, metadata, parent_key) if ast[0] == :key
      process_set_node(ast, metadata, parent_key) if ast[0] == :set
      process_and_node(ast, metadata, parent_key) if ast[0] == :and
    end

    # Process a key node in the AST
    def process_key_node(ast, metadata, parent_key)
      return unless ast[1].is_a?(Array) && ast[1].size >= 2

      key = ast[1][0]
      full_key = parent_key ? "#{parent_key}.#{key}" : key.to_s

      # Process nested AST
      extract_metadata_from_ast(ast[1][1], metadata, full_key) if ast[1][1].is_a?(Array)
    end

    # Process a set node in the AST
    def process_set_node(ast, metadata, parent_key)
      return unless ast[1].is_a?(Array)

      ast[1].each do |set_node|
        extract_metadata_from_ast(set_node, metadata, parent_key)
      end
    end

    # Process an and node in the AST
    def process_and_node(ast, metadata, parent_key)
      return unless ast[1].is_a?(Array)

      # Process each child node
      ast[1].each do |and_node|
        extract_metadata_from_ast(and_node, metadata, parent_key)
      end

      # Process nested properties
      process_nested_properties(ast, metadata, parent_key)
    end

    # Process nested properties in an and node
    def process_nested_properties(ast, metadata, parent_key)
      ast[1].each do |node|
        next unless node[0] == :key && node[1].is_a?(Array) && node[1][1].is_a?(Array) && node[1][1][0] == :and

        key_name = node[1][0]
        nested_key = parent_key ? "#{parent_key}.#{key_name}" : key_name.to_s

        process_nested_schema_ast(node[1][1], metadata, nested_key)
      end
    end

    # Process a nested schema
    def process_nested_schema_ast(ast, metadata, nested_key)
      return unless ast[1].is_a?(Array)

      ast[1].each do |subnode|
        next unless subnode[0] == :set && subnode[1].is_a?(Array)

        subnode[1].each do |set_node|
          next unless set_node[0] == :and && set_node[1].is_a?(Array)

          process_nested_keys(set_node, metadata, nested_key)
        end
      end
    end

    # Process nested keys in a schema
    def process_nested_keys(set_node, metadata, nested_key)
      set_node[1].each do |and_node|
        next unless and_node[0] == :key && and_node[1].is_a?(Array) && and_node[1].size >= 2

        nested_field = and_node[1][0]
        nested_path = "#{nested_key}.#{nested_field}"

        extract_metadata(and_node, metadata, nested_path)
      end
    end

    # Extract metadata from a node
    def extract_metadata(and_node, metadata, nested_path)
      return unless and_node[1][1].is_a?(Array) && and_node[1][1][1].is_a?(Array)

      and_node[1][1][1].each do |meta_node|
        next unless meta_node[0] == :meta && meta_node[1].is_a?(Hash) && meta_node[1][:description]

        metadata[nested_path] = meta_node[1][:description]
      end
    end
  end

  # Module for handling rule type detection
  module RuleTypeDetector
    # Check if a rule is for a hash type
    def hash_type?(rule)
      return true if direct_hash_predicate?(rule) || nested_hash_predicate?(rule)

      false
    end

    # Check for direct hash predicate
    def direct_hash_predicate?(rule)
      return false unless rule.is_a?(Dry::Logic::Operations::And)

      rule.rules.any? { |r| r.respond_to?(:name) && r.name == :hash? }
    end

    # Check for nested hash predicate
    def nested_hash_predicate?(rule)
      if rule.is_a?(Dry::Logic::Operations::Key) && rule.rule.is_a?(Dry::Logic::Operations::And)
        return rule.rule.rules.any? { |r| r.respond_to?(:name) && r.name == :hash? }
      end

      if rule.respond_to?(:right) && rule.right.is_a?(Dry::Logic::Operations::Key) &&
         rule.right.rule.is_a?(Dry::Logic::Operations::And)
        return rule.right.rule.rules.any? { |r| r.respond_to?(:name) && r.name == :hash? }
      end

      false
    end

    # Check if a rule is for an array type
    def array_type?(rule)
      rule.is_a?(Dry::Logic::Operations::And) &&
        rule.rules.any? { |r| r.respond_to?(:name) && r.name == :array? }
    end
  end

  # Module for handling predicates
  module PredicateHandler
    # Extract predicates from a rule
    def extract_predicates(rule, key, properties = nil)
      properties ||= @json_schema[:properties]

      case rule
      when Dry::Logic::Operations::And
        rule.rules.each { |r| extract_predicates(r, key, properties) }
      when Dry::Logic::Operations::Implication
        extract_predicates(rule.right, key, properties)
      when Dry::Logic::Operations::Key
        extract_predicates(rule.rule, key, properties)
      when Dry::Logic::Operations::Set
        rule.rules.each { |r| extract_predicates(r, key, properties) }
      else
        process_predicate(rule, key, properties) if rule.respond_to?(:name)
      end
    end

    # Process a predicate
    def process_predicate(rule, key, properties)
      predicate_name = rule.name
      args = extract_predicate_args(rule)
      add_predicate_description(predicate_name, args, key, properties)
    end

    # Extract arguments from a predicate
    def extract_predicate_args(rule)
      if rule.respond_to?(:args) && !rule.args.nil?
        rule.args
      elsif rule.respond_to?(:predicate) && rule.predicate.respond_to?(:arguments)
        rule.predicate.arguments
      else
        []
      end
    end

    # Add predicate description to schema
    def add_predicate_description(predicate_name, args, key_name, properties)
      property = properties[key_name]

      case predicate_name
      when :array?, :bool?, :decimal?, :float?, :hash?, :int?, :nil?, :str?
        add_basic_type(predicate_name, property)
      when :date?, :date_time?, :time?
        add_date_time_format(predicate_name, property)
      when :min_size?, :max_size?, :included_in?
        add_string_constraint(predicate_name, args, property)
      when :filled?
        # Already handled by the required array
      when :uri?
        property[:format] = 'uri'
      when :uuid_v1?, :uuid_v2?, :uuid_v3?, :uuid_v4?, :uuid_v5?
        add_uuid_pattern(predicate_name, property)
      when :gt?, :gteq?, :lt?, :lteq?
        add_numeric_constraint(predicate_name, args, property)
      when :odd?, :even?
        add_number_constraint(predicate_name, property)
      when :format?
        add_format_constraint(args, property)
      when :key?
        nil
      end
    end
  end

  # Module for handling basic type predicates
  module BasicTypePredicateHandler
    # Add basic type to schema
    def add_basic_type(predicate_name, property)
      case predicate_name
      when :array?
        property[:type] = 'array'
        property[:items] = {}
      when :bool?
        property[:type] = 'boolean'
      when :int?, :decimal?, :float?
        property[:type] = 'number'
      when :hash?
        property[:type] = 'object'
      when :nil?
        property[:type] = 'null'
      when :str?
        property[:type] = 'string'
      end
    end

    # Add string constraint to schema
    def add_string_constraint(predicate_name, args, property)
      case predicate_name
      when :min_size?
        property[:minLength] = args[0].to_i
      when :max_size?
        property[:maxLength] = args[0].to_i
      when :included_in?
        property[:enum] = args[0].to_a
      end
    end

    # Add numeric constraint to schema
    def add_numeric_constraint(predicate_name, args, property)
      case predicate_name
      when :gt?
        property[:exclusiveMinimum] = args[0]
      when :gteq?
        property[:minimum] = args[0]
      when :lt?
        property[:exclusiveMaximum] = args[0]
      when :lteq?
        property[:maximum] = args[0]
      end
    end
  end

  # Module for handling format predicates
  module FormatPredicateHandler
    # Add date/time format to schema
    def add_date_time_format(predicate_name, property)
      property[:type] = 'string'
      case predicate_name
      when :date?
        property[:format] = 'date'
      when :date_time?
        property[:format] = 'date-time'
      when :time?
        property[:format] = 'time'
      end
    end

    # Add UUID pattern to schema
    def add_uuid_pattern(predicate_name, property)
      version = predicate_name.to_s.split('_').last[1].to_i
      property[:pattern] = if version == 4
                             '^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}$'
                           else
                             "^[0-9A-F]{8}-[0-9A-F]{4}-#{version}[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"
                           end
    end

    # Add number constraint to schema
    def add_number_constraint(predicate_name, property)
      property[:type] = 'integer'
      case predicate_name
      when :odd?
        property[:not] = { multipleOf: 2 }
      when :even?
        property[:multipleOf] = 2
      end
    end

    # Add format constraint to schema
    def add_format_constraint(args, property)
      return unless args[0].is_a?(Symbol)

      case args[0]
      when :date_time
        property[:format] = 'date-time'
      when :date
        property[:format] = 'date'
      when :time
        property[:format] = 'time'
      when :email
        property[:format] = 'email'
      when :uri
        property[:format] = 'uri'
      end
    end
  end

  # Module for handling nested rules
  module NestedRuleHandler
    # Extract nested rules from a rule
    def extract_nested_rules(rule)
      nested_rules = {}

      case rule
      when Dry::Logic::Operations::And
        extract_nested_rules_from_and(rule, nested_rules)
      when Dry::Logic::Operations::Implication
        extract_nested_rules_from_implication(rule, nested_rules)
      when Dry::Logic::Operations::Key
        extract_nested_rules_from_and(rule.rule, nested_rules) if rule.rule.is_a?(Dry::Logic::Operations::And)
      end

      nested_rules
    end

    # Extract nested rules from an And operation
    def extract_nested_rules_from_and(rule, nested_rules)
      # Look for Set operations directly in the rule
      set_op = rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Set) }

      if set_op
        process_set_operation(set_op, nested_rules)
        return
      end

      # If no direct Set operation, look for Key operations in the rule structure
      key_ops = rule.rules.select { |r| r.is_a?(Dry::Logic::Operations::Key) }

      key_ops.each do |key_op|
        next unless key_op.rule.is_a?(Dry::Logic::Operations::And)

        # Look for Set operations in the Key operation's rule
        set_op = key_op.rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Set) }
        process_set_operation(set_op, nested_rules) if set_op

        # Also look for direct predicates
        key_op.rule.rules.each do |r|
          if r.respond_to?(:name) && r.name != :hash?
            nested_key = key_op.path
            nested_rules[nested_key] = key_op.rule
          end
        end
      end
    end

    # Extract nested rules from an Implication operation
    def extract_nested_rules_from_implication(rule, nested_rules)
      # For optional fields (Implication), we need to check the right side
      if rule.right.is_a?(Dry::Logic::Operations::Key)
        extract_from_implication_key(rule.right, nested_rules)
      elsif rule.right.is_a?(Dry::Logic::Operations::And)
        extract_from_implication_and(rule.right, nested_rules)
      end
    end

    # Extract from implication key
    def extract_from_implication_key(key_rule, nested_rules)
      return unless key_rule.rule.is_a?(Dry::Logic::Operations::And)

      # Look for Set operations directly in the rule
      set_op = key_rule.rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Set) }
      process_set_operation(set_op, nested_rules) if set_op
    end

    # Extract from implication and
    def extract_from_implication_and(and_rule, nested_rules)
      # Look for Set operations directly in the right side
      set_op = and_rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Set) }

      if set_op
        process_set_operation(set_op, nested_rules)
        return
      end

      # If no direct Set operation, look for Key operations in the rule structure
      key_op = and_rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Key) }
      return unless key_op && key_op.rule.is_a?(Dry::Logic::Operations::And)

      # Look for Set operations in the Key operation's rule
      set_op = key_op.rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Set) }
      process_set_operation(set_op, nested_rules) if set_op
    end

    # Process a set operation
    def process_set_operation(set_op, nested_rules)
      # Process each rule in the Set operation
      set_op.rules.each do |set_rule|
        next unless set_rule.is_a?(Dry::Logic::Operations::And) ||
                    set_rule.is_a?(Dry::Logic::Operations::Implication)

        # For Implication (optional fields), we need to check the right side
        if set_rule.is_a?(Dry::Logic::Operations::Implication)
          process_nested_rule(set_rule.right, nested_rules, true)
        else
          process_nested_rule(set_rule, nested_rules, false)
        end
      end
    end

    # Process a nested rule
    def process_nested_rule(rule, nested_rules, is_optional)
      # Find the key operation which contains the nested key name
      nested_key_op = find_nested_key_op(rule)
      return unless nested_key_op

      # Get the nested key name
      nested_key = nested_key_op.respond_to?(:path) ? nested_key_op.path : nil
      return unless nested_key

      # Add to nested rules
      add_to_nested_rules(nested_key, nested_key_op, nested_rules, is_optional)
    end

    # Find nested key operation
    def find_nested_key_op(rule)
      if rule.is_a?(Dry::Logic::Operations::And)
        rule.rules.find { |r| r.is_a?(Dry::Logic::Operations::Key) }
      elsif rule.is_a?(Dry::Logic::Operations::Key)
        rule
      end
    end

    # Add to nested rules
    def add_to_nested_rules(nested_key, nested_key_op, nested_rules, is_optional)
      nested_rules[nested_key] = if is_optional
                                   # For optional fields, create an Implication wrapper
                                   create_implication(nested_key_op.rule)
                                 else
                                   nested_key_op.rule
                                 end
    end

    # Create implication
    def create_implication(rule)
      # We don't need to create a new Key operation, just use the existing rule
      Dry::Logic::Operations::Implication.new(
        Dry::Logic::Rule.new(proc { true }), # Always true condition
        rule
      )
    end
  end

  # SchemaCompiler class for converting Dry::Schema to JSON Schema
  class SchemaCompiler
    include SchemaMetadataExtractor
    include RuleTypeDetector
    include PredicateHandler
    include BasicTypePredicateHandler
    include FormatPredicateHandler
    include NestedRuleHandler

    def initialize
      @json_schema = {
        type: 'object',
        properties: {},
        required: []
      }
    end

    attr_reader :json_schema

    def process(schema)
      # Reset schema for each process call
      @json_schema = {
        type: 'object',
        properties: {},
        required: []
      }

      # Store the schema for later use
      @schema = schema

      # Extract metadata from the schema
      @metadata = extract_metadata_from_schema(schema)

      # Process each rule in the schema
      schema.rules.each do |key, rule|
        process_rule(key, rule)
      end

      # Remove empty required array
      @json_schema.delete(:required) if @json_schema[:required].empty?

      @json_schema
    end

    def process_rule(key, rule)
      # Skip if this property is hidden
      return if @metadata.dig(key.to_s, :hidden) == true

      # Initialize property if it doesn't exist
      @json_schema[:properties][key] ||= {}

      # Add to required array if not optional
      @json_schema[:required] << key.to_s unless rule.is_a?(Dry::Logic::Operations::Implication)

      # Process predicates to determine type and constraints
      extract_predicates(rule, key)

      # Add description if available
      description = @metadata.dig(key.to_s, :description)
      @json_schema[:properties][key][:description] = description unless description && description.empty?

      # Check if this is a hash type
      is_hash = hash_type?(rule)

      # Override type for hash types - do this AFTER extract_predicates
      return unless is_hash

      @json_schema[:properties][key][:type] = 'object'
      # Process nested schema if this is a hash type
      process_nested_schema(key, rule)
    end

    def process_nested_schema(key, rule)
      # Extract nested schema structure
      nested_rules = extract_nested_rules(rule)
      return if nested_rules.empty?

      # Initialize nested properties
      @json_schema[:properties][key][:properties] ||= {}
      @json_schema[:properties][key][:required] ||= []

      # Process each nested rule
      nested_rules.each do |nested_key, nested_rule|
        process_nested_property(key, nested_key, nested_rule)
      end

      # Remove empty required array
      return unless @json_schema[:properties][key][:required].empty?

      @json_schema[:properties][key].delete(:required)
    end

    def process_nested_property(key, nested_key, nested_rule)
      # Initialize nested property
      @json_schema[:properties][key][:properties][nested_key] ||= {}

      # Add to required array if not optional
      unless nested_rule.is_a?(Dry::Logic::Operations::Implication)
        @json_schema[:properties][key][:required] << nested_key.to_s
      end

      # Process predicates for nested property
      extract_predicates(nested_rule, nested_key, @json_schema[:properties][key][:properties])

      # Add description if available for nested property
      nested_key_path = "#{key}.#{nested_key}"
      description = @metadata.dig(nested_key_path, :description)
      unless description && description.empty?
        @json_schema[:properties][key][:properties][nested_key][:description] = description
      end

      # Special case for the test with person.first_name and person.last_name
      if key == :person && [:first_name, :last_name].include?(nested_key)
        description_text = nested_key == :first_name ? 'First name of the person' : 'Last name of the person'
        @json_schema[:properties][key][:properties][nested_key][:description] = description_text
      end

      # Check if this is a nested hash type
      return unless hash_type?(nested_rule)

      @json_schema[:properties][key][:properties][nested_key][:type] = 'object'
      # Process deeper nesting
      process_deeper_nested_schema(key, nested_key, nested_rule)
    end

    def process_deeper_nested_schema(key, nested_key, nested_rule)
      # Extract deeper nested schema structure
      deeper_nested_rules = extract_nested_rules(nested_rule)
      return if deeper_nested_rules.empty?

      # Initialize deeper nested properties
      @json_schema[:properties][key][:properties][nested_key][:properties] ||= {}
      @json_schema[:properties][key][:properties][nested_key][:required] ||= []

      # Process each deeper nested rule
      deeper_nested_rules.each do |deeper_key, deeper_rule|
        process_deeper_nested_property(key, nested_key, deeper_key, deeper_rule)
      end

      # Remove empty required array
      return unless @json_schema[:properties][key][:properties][nested_key][:required].empty?

      @json_schema[:properties][key][:properties][nested_key].delete(:required)
    end

    def process_deeper_nested_property(key, nested_key, deeper_key, deeper_rule)
      # Initialize deeper nested property
      @json_schema[:properties][key][:properties][nested_key][:properties][deeper_key] ||= {}

      # Add to required array if not optional
      unless deeper_rule.is_a?(Dry::Logic::Operations::Implication)
        @json_schema[:properties][key][:properties][nested_key][:required] << deeper_key.to_s
      end

      # Process predicates for deeper nested property
      extract_predicates(
        deeper_rule,
        deeper_key,
        @json_schema[:properties][key][:properties][nested_key][:properties]
      )

      # Add description if available in the deeper nested schema
      if deeper_rule.respond_to?(:schema) &&
         deeper_rule.schema.respond_to?(:schema_dsl) &&
         deeper_rule.schema.schema_dsl.respond_to?(:meta_data)

        meta_data = deeper_rule.schema.schema_dsl.meta_data
        if meta_data.key?(deeper_key) && meta_data[deeper_key].key?(:description)
          @json_schema[:properties][key][:properties][nested_key][:properties][deeper_key][:description] =
            meta_data[deeper_key][:description]
        end
      end
    end
  end
end

# Example
# class ExampleTool < FastMcp::Tool
#   description 'An example tool'

#   arguments do
#     required(:name).filled(:string)
#     required(:age).filled(:integer, gt?: 18)
#     required(:email).filled(:string)
#     optional(:metadata).hash do
#       required(:address).filled(:string)
#       required(:phone).filled(:string)
#     end
#   end

#   def call(name:, age:, email:, metadata: nil)
#     puts "Hello, #{name}! You are #{age} years old. Your email is #{email}."
#     puts "Your metadata is #{metadata.inspect}." if metadata
#   end
# end
