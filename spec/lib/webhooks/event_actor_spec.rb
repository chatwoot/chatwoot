require 'rails_helper'

RSpec.describe Webhooks::EventActor do
  let(:account) { create(:account) }

  {
    user: 'user', agent_bot: 'agent_bot', automation_rule: 'automation_rule', contact: 'contact', inbox: 'inbox'
  }.each do |factory, type|
    it "serializes only the type and id of an account's #{type}" do
      actor = create(factory, account: account)

      expect(described_class.serialize(actor, account.id)).to eq(type: type, id: actor.id)
    end

    it "does not expose a #{type} from another account" do
      actor = create(factory, account: create(:account))

      expect(described_class.serialize(actor, account.id)).to be_nil
    end
  end

  it 'recognizes user membership in more than one account' do
    user = create(:user)
    create(:account_user, account: account, user: user)

    expect(described_class.serialize(user, account.id)).to eq(type: 'user', id: user.id)
  end

  it 'recognizes a global bot connected to an inbox in the account' do
    bot = create(:agent_bot, account: nil)
    create(:agent_bot_inbox, agent_bot: bot, inbox: create(:inbox, account: account))

    expect(described_class.serialize(bot, account.id)).to eq(type: 'agent_bot', id: bot.id)
  end

  it 'does not expose an unconnected global bot' do
    bot = create(:agent_bot, account: nil)

    expect(described_class.serialize(bot, account.id)).to be_nil
  end

  it 'does not infer an actor for system actions' do
    expect(described_class.serialize(nil, account.id)).to be_nil
  end

  it 'does not serialize an unsupported model even when it belongs to the account' do
    expect(described_class.serialize(create(:team, account: account), account.id)).to be_nil
  end

  it 'does not serialize an unsaved actor' do
    expect(described_class.serialize(build(:contact, account: account), account.id)).to be_nil
  end
end
