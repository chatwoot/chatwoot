class Autonomia::Agents::InstructionVersion < ApplicationRecord
  self.table_name = 'autonomia_agent_instruction_versions'

  belongs_to :agent, class_name: 'Autonomia::Agents::Agent',
                     foreign_key: :autonomia_agent_id, inverse_of: :instruction_versions
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  validates :instruction, presence: true
  validates :instruction_hash, presence: true
  validates :reason, presence: true
end
