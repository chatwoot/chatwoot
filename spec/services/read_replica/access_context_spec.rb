require 'rails_helper'

RSpec.describe ReadReplica::AccessContext do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by!(user: agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:team) { create(:team, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:conversation_participant, user: agent, conversation: conversation, account: account)
  end

  it 'captures authorization inputs before the request switches to the reader' do
    context = described_class.build(
      account: account,
      user: agent,
      account_user: account_user,
      params: { conversation_type: 'participating', team_id: team.id }
    )

    expect(context).to have_attributes(
      account_id: account.id,
      user_id: agent.id,
      role: 'agent',
      custom_role_id: nil,
      inbox_ids: [inbox.id],
      participant_conversation_ids: [conversation.id],
      mention_conversation_ids: [],
      team_id: team.id
    )
    expect(context.permissions).to eq(['agent'])
  end

  it 'captures mentioned conversation ids only for the mention filter' do
    create(:mention, account: account, conversation: conversation, user: agent)

    context = described_class.build(
      account: account,
      user: agent,
      account_user: account_user,
      params: { conversation_type: 'mention' }
    )

    expect(context.mention_conversation_ids).to eq([conversation.id])
    expect(context.participant_conversation_ids).to be_empty
  end
end
