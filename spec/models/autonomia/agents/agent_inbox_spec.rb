require 'rails_helper'

RSpec.describe Autonomia::Agents::AgentInbox do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(account: account, name: 'Agente', agent_type: 'custom')
  end
  let(:agent_bot) { AgentBot.create!(account: account, name: 'Espelho') }

  def build_link(overrides = {})
    described_class.new({ account: account, inbox: inbox, agent: agent, agent_bot: agent_bot }.merge(overrides))
  end

  describe 'tenancy validation' do
    it 'accepts a link where agent, inbox and agent_bot belong to the account' do
      # Arrange / Act
      link = build_link

      # Assert
      expect(link).to be_valid
    end

    it 'rejects an agent from another account' do
      # Arrange
      foreign_agent = Autonomia::Agents::Agent.create!(account: other_account, name: 'Alheio', agent_type: 'custom')

      # Act
      link = build_link(agent: foreign_agent)

      # Assert
      expect(link).not_to be_valid
      expect(link.errors[:agent]).to include('must belong to the same account')
    end

    it 'rejects an inbox from another account' do
      # Arrange
      foreign_inbox = create(:inbox, account: other_account)

      # Act
      link = build_link(inbox: foreign_inbox)

      # Assert
      expect(link).not_to be_valid
      expect(link.errors[:inbox]).to include('must belong to the same account')
    end

    it 'rejects an agent_bot from another account' do
      # Arrange
      foreign_bot = AgentBot.create!(account: other_account, name: 'Bot alheio')

      # Act
      link = build_link(agent_bot: foreign_bot)

      # Assert
      expect(link).not_to be_valid
      expect(link.errors[:agent_bot]).to include('must belong to the same account')
    end
  end
end
