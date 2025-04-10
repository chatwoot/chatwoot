require 'rails_helper'

describe AgentBots::ValidateBotService do
  describe '#perform' do
    it 'returns true for webhook bots' do
      agent_bot = create(:agent_bot)
      valid = described_class.new(agent_bot: agent_bot).perform
      expect(valid).to be true
    end
  end
end
