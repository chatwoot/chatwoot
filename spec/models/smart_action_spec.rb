require 'rails_helper'

RSpec.describe SmartAction do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:message_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validates_factory' do
    it 'creates valid note object' do
      smart_action = create(:smart_action)
      expect(smart_action.name).to eq 'Create Booking'
    end
  end

  describe '#custom_attributes' do
    let(:to) { 'Booking Page' }
    let(:from) { 'Messages' }
    let(:link) { 'https://test.com' }

    it 'stores custom attributes correctly' do
      smart_action = create(:smart_action, to: to, from: from, link: link)
      expect(smart_action.to).to eq 'Booking Page'
      expect(smart_action.from).to eq 'Messages'
      expect(smart_action.link).to eq 'https://test.com'
    end
  end

  describe '#manual_action?' do
    it 'returns true for manual action' do
      smart_action = create(:smart_action, event: SmartAction::MANUAL_ACTION.sample)
      expect(smart_action.manual_action?).to eq true
    end

    it 'returns false for non manual action' do
      smart_action = create(:smart_action, event: 'automated_response')
      expect(smart_action.manual_action?).to eq false
    end
  end

  describe 'event types' do
    context 'automated_response' do
      it 'creates automated response' do
        smart_action = create(:smart_action, event: 'automated_response', content: 'test content')
        expect(smart_action.content).to eq smart_action.conversation.messages.last.content
      end

      it 'sets assignee as sender' do
        conversation = create(:conversation, assignee: create(:user))
        smart_action = create(:smart_action, event: 'automated_response', conversation: conversation)
        expect(smart_action.conversation.messages.last.sender).to eq conversation.assignee
      end
    end

    context 'resolve_conversation' do
      it 'resolves conversation' do
        conversation = create(:conversation)
        smart_action = create(:smart_action, event: 'resolve_conversation', conversation: conversation)
        expect(smart_action.conversation.resolved?).to be_truthy
      end
    end

    context 'create_private_message' do
      it {
        conversation = create(:conversation)
        smart_action = create(:smart_action, event: 'create_private_message', conversation: conversation, content: 'private content')
        expect(smart_action.conversation.messages.last.private).to be_truthy
        expect(smart_action.conversation.messages.last.content).to eq 'private content'
      }
    end
  end
end
