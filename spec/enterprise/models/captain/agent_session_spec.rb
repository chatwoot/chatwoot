require 'rails_helper'

RSpec.describe Captain::AgentSession, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:subject) }
    it { is_expected.to belong_to(:result).optional }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:session_type).with_values(assistant: 0, copilot: 1).with_prefix(:session) }
  end

  describe '#subject' do
    it 'returns the conversation for an assistant session' do
      conversation = create(:conversation, account: account)
      session = create(:captain_agent_session, account: account, assistant: assistant, subject: conversation)

      expect(session.subject).to eq(conversation)
    end

    it 'returns the copilot thread for a copilot session' do
      user = create(:user, account: account)
      copilot_thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
      session = create(:captain_agent_session, :copilot, account: account, assistant: assistant, user: user, subject: copilot_thread)

      expect(session.subject).to eq(copilot_thread)
    end

    it 'returns nil when the subject record no longer exists' do
      conversation = create(:conversation, account: account)
      session = create(:captain_agent_session, account: account, assistant: assistant, subject: conversation)
      conversation.destroy

      expect(session.reload.subject).to be_nil
    end

    it 'is not valid when the subject type does not match the session type' do
      copilot_thread = create(:captain_copilot_thread, account: account, user: create(:user, account: account), assistant: assistant)
      session = build(:captain_agent_session, account: account, assistant: assistant, subject: copilot_thread)

      expect(session).not_to be_valid
      expect(session.errors[:subject_type]).to be_present
    end

    it 'is not valid when the subject belongs to a different account' do
      foreign_conversation = create(:conversation, account: create(:account))
      session = build(:captain_agent_session, account: account, assistant: assistant, subject: foreign_conversation)

      expect(session).not_to be_valid
      expect(session.errors[:subject]).to be_present
    end
  end

  describe '#result' do
    it 'returns the message for an assistant session' do
      conversation = create(:conversation, account: account)
      message = create(:message, account: account, conversation: conversation)
      session = create(:captain_agent_session, account: account, assistant: assistant, subject: conversation, result: message)

      expect(session.result).to eq(message)
    end

    it 'returns the copilot message for a copilot session' do
      user = create(:user, account: account)
      copilot_thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
      copilot_message = create(:captain_copilot_message, account: account, copilot_thread: copilot_thread)
      session = create(:captain_agent_session, :copilot, account: account, assistant: assistant, user: user,
                                                         subject: copilot_thread, result: copilot_message)

      expect(session.result).to eq(copilot_message)
    end

    it 'returns nil when result_id is nil' do
      session = create(:captain_agent_session, account: account, assistant: assistant)

      expect(session.result).to be_nil
    end

    it 'is not valid when the result belongs to a different account' do
      conversation = create(:conversation, account: account)
      foreign_message = create(:message, account: create(:account))
      session = build(:captain_agent_session, account: account, assistant: assistant, subject: conversation, result: foreign_message)

      expect(session).not_to be_valid
      expect(session.errors[:result]).to be_present
    end

    it 'is not valid when result_id/result_type are set directly for a different account' do
      conversation = create(:conversation, account: account)
      foreign_message = create(:message, account: create(:account))
      session = build(:captain_agent_session, account: account, assistant: assistant, subject: conversation,
                                              result_id: foreign_message.id, result_type: 'Message')

      expect(session).not_to be_valid
      expect(session.errors[:result]).to be_present
    end

    it 'is not valid when result_id/result_type are set directly for a stale id' do
      conversation = create(:conversation, account: account)
      session = build(:captain_agent_session, account: account, assistant: assistant, subject: conversation,
                                              result_id: 0, result_type: 'Message')

      expect(session).not_to be_valid
      expect(session.errors[:result]).to be_present
    end
  end

  describe 'account' do
    it 'is derived from the assistant when created via the assistant association' do
      conversation = create(:conversation, account: account)
      session = assistant.agent_sessions.create!(subject: conversation, session_type: :assistant)

      expect(session.account).to eq(account)
    end

    it 'overrides a mismatched explicit account with the assistant account' do
      conversation = create(:conversation, account: account)
      session = build(:captain_agent_session, account: create(:account), assistant: assistant, subject: conversation)

      expect(session).to be_valid
      expect(session.account).to eq(account)
    end
  end

  describe 'defaults' do
    it 'defaults faq_ids, document_ids, scenario_ids and run_context' do
      session = create(:captain_agent_session, account: account, assistant: assistant)

      expect(session.faq_ids).to eq([])
      expect(session.document_ids).to eq([])
      expect(session.scenario_ids).to eq([])
      expect(session.run_context).to eq({})
    end
  end

  describe 'factory' do
    it 'builds a valid assistant session' do
      session = create(:captain_agent_session, account: account, assistant: assistant)

      expect(session).to be_valid
      expect(session).to be_session_assistant
      expect(session.subject).to be_a(Conversation)
    end

    it 'builds a valid copilot session' do
      session = create(:captain_agent_session, :copilot, account: account, assistant: assistant)

      expect(session).to be_valid
      expect(session).to be_session_copilot
      expect(session.subject).to be_a(CopilotThread)
      expect(session.user).to be_present
    end
  end
end
