require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe AgentBot, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:agent_bot_inboxes) }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'concerns' do
    it_behaves_like 'access_tokenable'
    it_behaves_like 'avatarable'
  end
end
