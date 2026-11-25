require 'rails_helper'

RSpec.describe AgentBotObserver do
  describe 'associations' do
    it { is_expected.to belong_to(:agent_bot) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:account) }
  end

  it 'refuses the same bot observing the same inbox twice' do
    observer = create(:agent_bot_observer)
    duplicate = build(:agent_bot_observer, inbox: observer.inbox, agent_bot: observer.agent_bot)

    expect(duplicate).not_to be_valid
  end

  it 'takes the account from the inbox' do
    observer = create(:agent_bot_observer)

    expect(observer.account).to eq(observer.inbox.account)
  end

  it 'leaves the inbox without a responder' do
    observer = create(:agent_bot_observer)

    expect(observer.inbox.active_bot?).to be(false)
    expect(observer.inbox.agent_bot).to be_nil
  end
end
