# frozen_string_literal: true

# Validates a workflow JSON structure before saving or executing.
# Checks structure, required nodes, connectivity, and handle compatibility.
#
# Usage:
#   validator = Agent::WorkflowValidator.new(workflow_json)
#   validator.valid?  # => true/false
#   validator.errors  # => ["Workflow must have exactly one trigger node"]
class Agent::WorkflowValidator
  SCHEMA_VERSION = 'v2'
  VALID_NODE_TYPES = %w[
    trigger system_prompt knowledge_retrieval llm_call
    condition loop set_variable delay
    http_request handoff reply code
  ].freeze

  HANDLE_TYPES = %w[flow data messages].freeze

  attr_reader :errors

  def initialize(workflow)
    @workflow = workflow.is_a?(String) ? JSON.parse(workflow) : workflow
    @errors = []
  end

  def valid?
    @errors = []
    validate_structure
    return false if @errors.any?

    validate_schema_version
    validate_nodes
    validate_edges
    validate_trigger
    validate_connectivity
    @errors.empty?
  end

  private

  def validate_structure
    return if @workflow.is_a?(Hash) && @workflow['nodes'].is_a?(Array) && @workflow['edges'].is_a?(Array)

    @errors << 'Workflow must be a JSON object with "nodes" and "edges" arrays'
  end

  def validate_schema_version
    version = @workflow['schema_version']
    @errors << "Unsupported schema version: #{version}" if version.present? && version != SCHEMA_VERSION
  end

  def validate_nodes
    nodes = @workflow['nodes']
    return if nodes.blank?

    node_ids = Set.new
    nodes.each do |node|
      unless node['id'].present? && node['type'].present?
        @errors << "Each node must have 'id' and 'type' fields"
        next
      end

      @errors << "Duplicate node id: #{node['id']}" if node_ids.include?(node['id'])
      node_ids << node['id']

      @errors << "Unknown node type: #{node['type']}" unless VALID_NODE_TYPES.include?(node['type'])
    end
  end

  def validate_edges
    edges = @workflow['edges']
    return if edges.blank?

    node_ids = Set.new(@workflow['nodes']&.pluck('id'))
    edges.each do |edge|
      unless edge['source'].present? && edge['target'].present?
        @errors << "Each edge must have 'source' and 'target' fields"
        next
      end

      @errors << "Edge references unknown source node: #{edge['source']}" unless node_ids.include?(edge['source'])
      @errors << "Edge references unknown target node: #{edge['target']}" unless node_ids.include?(edge['target'])

      validate_handle_types(edge) if edge['source_handle'].present? || edge['target_handle'].present?
    end
  end

  def validate_handle_types(edge)
    source_type = extract_handle_type(edge['source_handle'])
    target_type = extract_handle_type(edge['target_handle'])
    return if source_type.nil? || target_type.nil?

    return if source_type == target_type

    @errors << "Handle type mismatch on edge #{edge['source']}->#{edge['target']}: #{source_type} vs #{target_type}"
  end

  def extract_handle_type(handle_id)
    return nil if handle_id.blank?

    # Handle IDs follow pattern: flow_out, data_in, messages_out, etc.
    prefix = handle_id.split('_').first
    HANDLE_TYPES.include?(prefix) ? prefix : nil
  end

  def validate_trigger
    triggers = @workflow['nodes']&.select { |n| n['type'] == 'trigger' } || []
    @errors << 'Workflow must have exactly one trigger node' if triggers.size != 1
  end

  def validate_connectivity
    nodes = @workflow['nodes'] || []
    edges = @workflow['edges'] || []
    return if nodes.size <= 1

    # Build adjacency (undirected) to check all nodes are reachable from trigger
    adjacency = Hash.new { |h, k| h[k] = Set.new }
    edges.each do |edge|
      adjacency[edge['source']] << edge['target']
      adjacency[edge['target']] << edge['source']
    end

    trigger = nodes.find { |n| n['type'] == 'trigger' }
    return unless trigger

    visited = Set.new
    queue = [trigger['id']]
    while queue.any?
      current = queue.shift
      next if visited.include?(current)

      visited << current
      adjacency[current].each { |neighbor| queue << neighbor unless visited.include?(neighbor) }
    end

    disconnected = nodes.reject { |n| visited.include?(n['id']) }
    return if disconnected.empty?

    @errors << "#{disconnected.size} node(s) not connected to the trigger: #{disconnected.pluck('id').join(', ')}"
  end
end
