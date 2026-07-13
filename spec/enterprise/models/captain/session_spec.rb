require 'rails_helper'

RSpec.describe Captain::Session, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:subject_id) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:session_type).with_values(assistant: 0, copilot: 1).with_prefix(:session) }
  end

  describe '#subject' do
    it 'returns the conversation for an assistant session' do
      conversation = create(:conversation, account: account)
      session = create(:captain_session, account: account, assistant: assistant, subject_id: conversation.id)

      expect(session.subject).to eq(conversation)
    end

    it 'returns the copilot thread for a copilot session' do
      user = create(:user, account: account)
      copilot_thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
      session = create(:captain_session, :copilot, account: account, assistant: assistant, user: user, subject_id: copilot_thread.id)

      expect(session.subject).to eq(copilot_thread)
    end

    it 'returns nil when the subject record no longer exists' do
      session = create(:captain_session, account: account, assistant: assistant, subject_id: 0)

      expect(session.subject).to be_nil
    end
  end

  describe '#result' do
    it 'returns the message for an assistant session' do
      conversation = create(:conversation, account: account)
      message = create(:message, account: account, conversation: conversation)
      session = create(:captain_session, account: account, assistant: assistant, subject_id: conversation.id, result_id: message.id)

      expect(session.result).to eq(message)
    end

    it 'returns the copilot message for a copilot session' do
      user = create(:user, account: account)
      copilot_thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
      copilot_message = create(:captain_copilot_message, account: account, copilot_thread: copilot_thread)
      session = create(:captain_session, :copilot, account: account, assistant: assistant, user: user,
                                                   subject_id: copilot_thread.id, result_id: copilot_message.id)

      expect(session.result).to eq(copilot_message)
    end

    it 'returns nil when result_id is nil' do
      session = create(:captain_session, account: account, assistant: assistant)

      expect(session.result).to be_nil
    end
  end

  describe 'defaults' do
    it 'defaults faq_ids, document_ids, scenario_ids and run_context' do
      session = create(:captain_session, account: account, assistant: assistant)

      expect(session.faq_ids).to eq([])
      expect(session.document_ids).to eq([])
      expect(session.scenario_ids).to eq([])
      expect(session.run_context).to eq({})
    end
  end

  describe 'factory' do
    it 'builds a valid assistant session' do
      session = create(:captain_session, account: account, assistant: assistant)

      expect(session).to be_valid
      expect(session).to be_session_assistant
      expect(session.subject).to be_a(Conversation)
    end

    it 'builds a valid copilot session' do
      session = create(:captain_session, :copilot, account: account, assistant: assistant)

      expect(session).to be_valid
      expect(session).to be_session_copilot
      expect(session.subject).to be_a(CopilotThread)
      expect(session.user).to be_present
    end
  end
end
