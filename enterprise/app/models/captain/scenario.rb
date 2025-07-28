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

  before_save :resolve_tool_references

  private

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

    available_tool_ids = self.class.available_tool_ids
    invalid_tools = tool_ids - available_tool_ids

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
