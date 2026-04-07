# == Schema Information
#
# Table name: captain_scenarios
#
#  id           :bigint           not null, primary key
#  description  :text
#  enabled      :boolean          default(TRUE), not null
#  instruction  :text
#  title        :string
#  tools        :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  assistant_id :bigint           not null
#
# Indexes
#
#  index_captain_scenarios_on_account_id                (account_id)
#  index_captain_scenarios_on_assistant_id              (assistant_id)
#  index_captain_scenarios_on_assistant_id_and_enabled  (assistant_id,enabled)
#  index_captain_scenarios_on_enabled                   (enabled)
#
class Captain::Scenario < ApplicationRecord
  include Concerns::CaptainToolsHelpers
  include Concerns::Agentable

  # OpenAI enforces a 64-char limit on function names. The ai-agents gem
  # prepends "handoff_to_" (11 chars), so we keep a safety margin and cap
  # the full tool name to MAX_HANDOFF_TOOL_NAME_LENGTH (60 chars).
  # Format: "scenario_{id}_{slug}_agent" for persisted records (stable + readable),
  # and "scenario_draft_{slug}_agent" for unsaved records, with slug truncated
  # based on the available length budget.
  HANDOFF_TOOL_PREFIX = 'handoff_to_'.freeze
  HANDOFF_KEY_PREFIX = 'scenario'.freeze
  HANDOFF_KEY_SUFFIX = 'agent'.freeze
  MAX_HANDOFF_TOOL_NAME_LENGTH = 60
  MAX_AGENT_NAME_LENGTH = MAX_HANDOFF_TOOL_NAME_LENGTH - HANDOFF_TOOL_PREFIX.length
  MAX_HANDOFF_SLUG_LENGTH = 24

  self.table_name = 'captain_scenarios'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account

  validates :title, presence: true
  validates :description, presence: true
  validates :instruction, presence: true
  validates :assistant_id, presence: true
  validates :account_id, presence: true
  validate :validate_instruction_tools

  scope :enabled, -> { where(enabled: true) }

  delegate :temperature, :feature_faq, :feature_memory, :product_name, :response_guidelines, :guardrails, to: :assistant

  before_save :resolve_tool_references

  def handoff_key
    [handoff_id_key, compact_handoff_slug, HANDOFF_KEY_SUFFIX].compact.join('_')
  end

  def prompt_context
    {
      title: title,
      instructions: resolved_instructions,
      tools: resolved_tools,
      assistant_name: assistant.name.downcase.gsub(/\s+/, '_'),
      response_guidelines: response_guidelines || [],
      guardrails: guardrails || []
    }
  end

  private

  def agent_name
    handoff_key
  end

  def handoff_id_key
    return "#{HANDOFF_KEY_PREFIX}_#{id}" if id.present?

    "#{HANDOFF_KEY_PREFIX}_draft"
  end

  def compact_handoff_slug
    slug = title.to_s.parameterize(separator: '_').presence
    return nil if slug.blank?

    max_slug_length = [MAX_HANDOFF_SLUG_LENGTH, dynamic_slug_max_length].min
    return nil if max_slug_length <= 0

    slug.first(max_slug_length).sub(/_+\z/, '').presence
  end

  def dynamic_slug_max_length
    # handoff_to_#{scenario_<id>_<slug>_agent}
    MAX_AGENT_NAME_LENGTH - handoff_id_key.length - HANDOFF_KEY_SUFFIX.length - 2
  end

  def agent_tools
    resolved_tools.map { |tool| resolve_tool_instance(tool) }
  end

  def resolved_instructions
    instruction.gsub(TOOL_REFERENCE_REGEX, '`\1` tool')
  end

  def resolved_tools
    return [] if tools.blank?

    available_tools = assistant.available_agent_tools
    tools.filter_map do |tool_id|
      available_tools.find { |tool| tool[:id] == tool_id }
    end
  end

  def resolve_tool_instance(tool_metadata)
    tool_id = tool_metadata[:id]

    if tool_metadata[:custom]
      custom_tool = Captain::CustomTool.find_by(slug: tool_id, account_id: account_id, enabled: true)
      custom_tool&.tool(assistant)
    else
      tool_class = self.class.resolve_tool_class(tool_id)
      tool_class&.new(assistant)
    end
  end

  # Validates that all tool references in the instruction are valid.
  # Parses the instruction for tool references and checks if they exist
  # in the available tools configuration.
  #
  # @return [void]
  # @api private
  # @example Valid instruction
  #   scenario.instruction = "Use [Add Contact Note](tool://add_contact_note) to document"
  #   scenario.valid? # => true
  #
  # @example Invalid instruction
  #   scenario.instruction = "Use [Invalid Tool](tool://invalid_tool) to process"
  #   scenario.valid? # => false
  #   scenario.errors[:instruction] # => ["contains invalid tools: invalid_tool"]
  def validate_instruction_tools
    return if instruction.blank?

    tool_ids = extract_tool_ids_from_text(instruction)
    return if tool_ids.empty?

    all_available_tool_ids = assistant.available_tool_ids
    invalid_tools = tool_ids - all_available_tool_ids

    return unless invalid_tools.any?

    errors.add(:instruction, "contains invalid tools: #{invalid_tools.join(', ')}")
  end

  # Resolves tool references from the instruction text into the tools field.
  # Parses the instruction for tool references and materializes them as
  # tool IDs stored in the tools JSONB field.
  #
  # @return [void]
  # @api private
  # @example
  #   scenario.instruction = "First [@Add Private Note](tool://add_private_note) then [@Update Priority](tool://update_priority)"
  #   scenario.save!
  #   scenario.tools # => ["add_private_note", "update_priority"]
  #
  #   scenario.instruction = "No tools mentioned here"
  #   scenario.save!
  #   scenario.tools # => nil
  def resolve_tool_references
    return if instruction.blank?

    tool_ids = extract_tool_ids_from_text(instruction)
    self.tools = tool_ids.presence
  end
end
