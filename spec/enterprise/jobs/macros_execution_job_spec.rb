require 'rails_helper'

RSpec.describe MacrosExecutionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
  let(:macro) { create(:macro, account: account, actions: [{ 'action_name' => 'resolve_conversation' }]) }

  before do
    create(:inbox_member, user: user, inbox: inbox)
    user.account_users.find_by!(account: account).update!(custom_role: custom_role)
  end

  it 'executes only on assigned or participating conversations for a restricted role' do
    assigned_conversation = create(:conversation, account: account, inbox: inbox, assignee: user)
    participating_conversation = create(:conversation, account: account, inbox: inbox)
    create(:conversation_participant, account: account, conversation: participating_conversation, user: user)
    unrelated_conversation = create(:conversation, account: account, inbox: inbox)
    conversation_ids = [assigned_conversation.display_id, participating_conversation.display_id, unrelated_conversation.display_id]

    described_class.perform_now(macro, conversation_ids: conversation_ids, user: user)

    expect(assigned_conversation.reload).to be_resolved
    expect(participating_conversation.reload).to be_resolved
    expect(unrelated_conversation.reload).to be_open
  end

  it 'rechecks custom-role permissions when a queued job runs' do
    custom_role.update!(permissions: ['conversation_manage'])
    conversation = create(:conversation, account: account, inbox: inbox)
    described_class.perform_later(macro, conversation_ids: [conversation.display_id], user: user)
    custom_role.update!(permissions: ['conversation_participating_manage'])

    expect(Macros::ExecutionService).not_to receive(:new)

    perform_enqueued_jobs(only: described_class)

    expect(conversation.reload).to be_open
  end
end
