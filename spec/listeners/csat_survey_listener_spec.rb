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
end
