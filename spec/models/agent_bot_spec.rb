require 'rails_helper'

RSpec.describe AgentBot, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:agent_bot_inboxes) }
    it { is_expected.to have_many(:inboxes) }
  end
end
