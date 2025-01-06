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
    let(:handover_team) { create(:team, name: 'Handover Team', high_priority: true) }

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

    context 'escalate_conversation' do
      it 'escalates conversation' do
        conversation = create(:conversation, account_id: handover_team.account_id)
        expect(conversation.team_id).not_to eq handover_team.id

        smart_action = create(:smart_action, event: 'escalate_conversation', conversation: conversation)
        expect(smart_action.conversation.team_id).to eq handover_team.id
      end
    end

    context 'handover_conversation' do
      it 'hands over conversation to team' do
        conversation = create(:conversation, account_id: handover_team.account_id)
        expect(conversation.team_id).not_to eq handover_team.id

        smart_action = create(:smart_action, event: 'handover_conversation', conversation: conversation)
        expect(smart_action.conversation.team_id).to eq handover_team.id
      end
    end

    context 'record_message_score' do
      it 'records outgoing message score' do
        conversation = create(:conversation)
        message = create(:message, conversation: conversation)

        smart_action = create(:smart_action, event: 'record_message_score', message: message, conversation: conversation, score: 3)
        expect(message.agent_score).to eq 3
      end

      context 'with criteria' do
        let(:criteria) { { 'language_level' => 5, 'grammar' => 4, 'professionalism' => 3, 'tonality' => 2 } }

        it 'records outgoing message score with criteria' do
          conversation = create(:conversation)
          message = create(:message, conversation: conversation)

          smart_action = create(:smart_action, event: 'record_message_score', message: message, conversation: conversation, score: 3,
                                               criteria: criteria)
          expect(message.agent_score).to eq 3
          expect(message.agent_score_criteria).to eq criteria
        end
      end
    end

    context 'record_incoming_message_sentiment' do
      it 'records incoming message contact_sentiment' do
        conversation = create(:conversation)
        message = create(:message, conversation: conversation)

        smart_action = create(:smart_action, event: 'record_message_sentiment', message: message, conversation: conversation, sentiment: 'angry')
        expect(message.contact_sentiment).to eq 'Angry'
      end
    end
  end
end
