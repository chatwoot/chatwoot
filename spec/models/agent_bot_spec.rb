require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe AgentBot do
  describe 'associations' do
    it { is_expected.to have_many(:agent_bot_inboxes) }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'concerns' do
    it_behaves_like 'access_tokenable'
    it_behaves_like 'avatarable'
  end

  context 'when it validates outgoing_url length' do
    let(:agent_bot) { create(:agent_bot) }

    it 'valid when within limit' do
      agent_bot.outgoing_url = 'a' * Limits::URL_LENGTH_LIMIT
      expect(agent_bot.valid?).to be true
    end

    it 'invalid when crossed the limit' do
      agent_bot.outgoing_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
      agent_bot.valid?
      expect(agent_bot.errors[:outgoing_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
    end
  end
end
