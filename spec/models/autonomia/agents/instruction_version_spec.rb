require 'rails_helper'

# G2 — versionamento da instrução: snapshot + rollback atômico, com idempotência por hash e
# blindagem de tenancy (uma versão de outro agente nunca restaura neste).
RSpec.describe Autonomia::Agents::InstructionVersion, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  let(:agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Agente', agent_type: 'custom', mode: :manual, instruction: 'v1'
    )
  end

  describe '#record_instruction_version!' do
    it 'creates a version row snapshotting the current instruction, reason and author' do
      # Act
      version = agent.record_instruction_version!(reason: 'manual_edit', created_by: user)

      # Assert
      expect(version).to be_persisted
      expect(version.instruction).to eq('v1')
      expect(version.reason).to eq('manual_edit')
      expect(version.created_by).to eq(user)
      expect(version.account).to eq(account)
      expect(version.instruction_hash).to eq(Digest::SHA256.hexdigest('v1'))
    end

    it 'is idempotent: a second call with the same instruction hash is a no-op' do
      # Arrange
      agent.record_instruction_version!(reason: 'manual_edit', created_by: user)

      # Act
      second = agent.record_instruction_version!(reason: 'kb_refresh')

      # Assert
      expect(second).to be_nil
      expect(agent.instruction_versions.count).to eq(1)
    end

    it 'records a new row when the instruction text changed' do
      # Arrange
      agent.record_instruction_version!(reason: 'manual_edit', created_by: user)

      # Act
      agent.update!(instruction: 'v2')
      agent.record_instruction_version!(reason: 'manual_edit', created_by: user)

      # Assert
      expect(agent.instruction_versions.count).to eq(2)
    end

    it 'is a no-op when the agent has no instruction' do
      # Arrange
      blank_agent = Autonomia::Agents::Agent.create!(
        account: account, name: 'Rascunho', agent_type: 'custom'
      )

      # Act / Assert
      expect(blank_agent.record_instruction_version!(reason: 'manual_edit')).to be_nil
      expect(blank_agent.instruction_versions.count).to eq(0)
    end
  end

  describe '#restore_instruction!' do
    it 'sets the instruction to the version text and records a rollback version' do
      # Arrange
      v1 = agent.record_instruction_version!(reason: 'manual_edit', created_by: user)
      agent.update!(instruction: 'v2')

      # Act
      result = agent.restore_instruction!(v1, created_by: user)

      # Assert
      expect(result).to be_truthy
      expect(agent.reload.instruction).to eq('v1')
      rollback = agent.instruction_versions.order(:created_at).last
      expect(rollback.reason).to eq('rollback')
      expect(rollback.instruction).to eq('v1')
      expect(rollback.created_by).to eq(user)
    end

    it 'rejects a version that belongs to another agent' do
      # Arrange
      other_agent = Autonomia::Agents::Agent.create!(
        account: account, name: 'Outro', agent_type: 'custom', mode: :manual, instruction: 'x'
      )
      foreign = other_agent.record_instruction_version!(reason: 'manual_edit')

      # Act
      result = agent.restore_instruction!(foreign, created_by: user)

      # Assert
      expect(result).to be(false)
      expect(agent.reload.instruction).to eq('v1')
    end
  end
end
