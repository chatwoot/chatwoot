require 'rails_helper'

RSpec.describe MacrosExecutionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:macro) { create(:macro, account: account, actions: [{ 'action_name' => 'resolve_conversation' }]) }

  context 'when the user is an administrator' do
    let(:user) { create(:user, account: account, role: :administrator) }

    it 'executes without inbox membership' do
      described_class.perform_now(macro, conversation_ids: [conversation.display_id], user: user)

      expect(conversation.reload).to be_resolved
    end
  end

  context 'when the user belongs to the inbox' do
    before { create(:inbox_member, user: user, inbox: inbox) }

    it 'executes the macro' do
      described_class.perform_now(macro, conversation_ids: [conversation.display_id], user: user)

      expect(conversation.reload).to be_resolved
    end

    it 'skips inaccessible conversations and continues executing accessible ones' do
      forbidden_conversation = create(:conversation, account: account, status: :open)

      described_class.perform_now(macro, conversation_ids: [forbidden_conversation.display_id, conversation.display_id], user: user)

      expect(forbidden_conversation.reload).to be_open
      expect(conversation.reload).to be_resolved
    end

    it 'rechecks inbox access when a queued job runs' do
      described_class.perform_later(macro, conversation_ids: [conversation.display_id], user: user)
      inbox.inbox_members.find_by!(user: user).destroy!

      expect(Macros::ExecutionService).not_to receive(:new)

      perform_enqueued_jobs(only: described_class)

      expect(conversation.reload).to be_open
    end

    it 'skips execution and logs when account membership is removed after enqueueing' do
      described_class.perform_later(macro, conversation_ids: [conversation.display_id], user: user)
      account.account_users.find_by!(user: user).destroy!
      allow(Rails.logger).to receive(:info).and_call_original

      expect(Macros::ExecutionService).not_to receive(:new)

      perform_enqueued_jobs(only: described_class)

      expect(conversation.reload).to be_open
      expect(Rails.logger).to have_received(:info).with({
        event: 'macro_execution_skipped',
        reason: 'missing_account_membership',
        account_id: account.id,
        macro_id: macro.id,
        user_id: user.id,
        conversation_ids: [conversation.id],
        conversation_display_ids: [conversation.display_id]
      }.to_json).once
    end
  end

  context 'when the user belongs to the conversation team' do
    let(:team) { create(:team, account: account, allow_auto_assign: false) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, team: team, status: :open) }

    before { create(:team_member, user: user, team: team) }

    it 'executes without inbox membership' do
      described_class.perform_now(macro, conversation_ids: [conversation.display_id], user: user)

      expect(conversation.reload).to be_resolved
    end

    it 'rechecks team access when a queued job runs' do
      described_class.perform_later(macro, conversation_ids: [conversation.display_id], user: user)
      team.team_members.find_by!(user: user).destroy!

      expect(Macros::ExecutionService).not_to receive(:new)

      perform_enqueued_jobs(only: described_class)

      expect(conversation.reload).to be_open
    end
  end

  context 'when the user cannot view the conversation' do
    it 'skips all macro actions and logs the denied conversation' do
      allow(Rails.logger).to receive(:info).and_call_original
      expect(Macros::ExecutionService).not_to receive(:new)

      described_class.perform_now(macro, conversation_ids: [conversation.display_id], user: user)

      expect(conversation.reload).to be_open
      expect(Rails.logger).to have_received(:info).with({
        event: 'macro_execution_skipped',
        reason: 'conversation_access_denied',
        account_id: account.id,
        macro_id: macro.id,
        user_id: user.id,
        conversation_ids: [conversation.id],
        conversation_display_ids: [conversation.display_id]
      }.to_json).once
    end
  end
end
