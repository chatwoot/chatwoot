require 'rails_helper'

describe AgentBots::ValidateBotService do
  describe '#perform' do
    it 'returns true if bot_type is not csml' do
      agent_bot = create(:agent_bot)
      valid = described_class.new(agent_bot: agent_bot).perform
      expect(valid).to be true
    end

    it 'returns true if validate csml returns true' do
      agent_bot = create(:agent_bot, :skip_validation, type: 'csml', bot_config: {})
      csml_client = double
      allow(CsmlEngine).to receive(:new).and_return(csml_client)
      allow(csml_client).to receive(:validate).and_return({ 'valid': true })

      valid = described_class.new(agent_bot: agent_bot).perform
      expect(valid).to be true
      expect(CsmlEngine).to have_received(:new)
    end
  end
end
