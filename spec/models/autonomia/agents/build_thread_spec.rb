require 'rails_helper'

RSpec.describe Autonomia::Agents::BuildThread do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  describe 'tenancy validation' do
    it 'accepts a thread without an agent (draft interview)' do
      # Arrange / Act
      thread = described_class.new(account: account)

      # Assert
      expect(thread).to be_valid
    end

    it 'accepts a thread whose agent belongs to the same account' do
      # Arrange
      agent = Autonomia::Agents::Agent.create!(account: account, name: 'Agente', agent_type: 'custom')

      # Act
      thread = described_class.new(account: account, agent: agent)

      # Assert
      expect(thread).to be_valid
    end

    it 'rejects a thread whose agent belongs to another account' do
      # Arrange
      foreign_agent = Autonomia::Agents::Agent.create!(account: other_account, name: 'Alheio', agent_type: 'custom')

      # Act
      thread = described_class.new(account: account, agent: foreign_agent)

      # Assert
      expect(thread).not_to be_valid
      expect(thread.errors[:agent]).to include('must belong to the same account')
    end
  end
end
