require 'rails_helper'
describe CsatSurveyListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(
      :message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation,
                content_type: :input_csat,
                content_attributes: { 'submitted_values': { 'csat_survey_response': { 'rating': 5, 'feedback_message': 'hello' } } }
    )
  end
  let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
  let!(:csat_enabled_inbox) { create(:inbox, account: account, csat_survey_enabled: true) }
  let!(:resolved_conversation) { create(:conversation, account: account, inbox: csat_enabled_inbox, status: :resolved) }

  describe '#message_updated' do
    let(:event_name) { 'message.updated' }
    let(:response_builder) { double }

    context 'when CsatSurveys::ResponseBuilder' do
      it 'triggers if message is input csat' do
        expect(response_builder).to receive(:perform)
        expect(CsatSurveys::ResponseBuilder).to receive(:new).with(message: message).and_return(response_builder).once
        listener.message_updated(event)
      end

      it 'will not trigger if message is not input csat' do
        message = create(:message)
        event = Events::Base.new(event_name, Time.zone.now, message: message)
        expect(CsatSurveys::ResponseBuilder).not_to receive(:new).with(message: message)
        listener.message_updated(event)
      end
    end
  end

  describe '#conversation_status_changed' do
    let(:event_name) { 'conversation.status_changed' }
    let(:csat_service) { double }

    before do
      allow(resolved_conversation).to receive(:saved_change_to_status?).and_return(true)
    end

    context 'when conversation is resolved and CSAT is enabled' do
      it 'triggers CSAT survey service' do
        event = Events::Base.new(event_name, Time.zone.now, conversation: resolved_conversation)
        expect(csat_service).to receive(:perform)
        expect(CsatSurveyService).to receive(:new).with(conversation: resolved_conversation).and_return(csat_service)

        listener.conversation_status_changed(event)
      end
    end

    context 'when conversation is not resolved' do
      it 'does not trigger CSAT survey service' do
        open_conversation = create(:conversation, account: account, inbox: csat_enabled_inbox, status: :open)
        event = Events::Base.new(event_name, Time.zone.now, conversation: open_conversation)

        expect(CsatSurveyService).not_to receive(:new)
        listener.conversation_status_changed(event)
      end
    end
  end
end
