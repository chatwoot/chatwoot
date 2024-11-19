require 'rails_helper'

RSpec.describe AgentBotInbox do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:agent_bot_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:agent_bot) }
    it { is_expected.to belong_to(:inbox) }
  end
end
