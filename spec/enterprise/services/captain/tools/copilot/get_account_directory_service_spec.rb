require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetAccountDirectoryService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:agent) { create(:user, account: account) }
  let!(:member_inbox) { create(:inbox, account: account) }
  let!(:other_inbox) { create(:inbox, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: member_inbox)
    create(:campaign, account: account, inbox: member_inbox)
  end

  it 'lists every inbox and campaign for an administrator' do
    result = described_class.new(assistant, user: create(:user, :administrator, account: account)).execute(sections: %w[inboxes campaigns])

    expect(result['inboxes'].pluck(:id)).to contain_exactly(member_inbox.id, other_inbox.id)
    expect(result['campaigns'].size).to eq(1)
  end

  it 'lists only an agent\'s own inboxes and no campaigns' do
    result = described_class.new(assistant, user: agent).execute(sections: %w[inboxes campaigns])

    expect(result['inboxes'].pluck(:id)).to contain_exactly(member_inbox.id)
    expect(result['campaigns']).to eq('Only administrators can see campaigns')
  end
end
