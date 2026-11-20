require 'rails_helper'

describe CsatSurveys::ResponseBuilder do
  let(:message) do
    create(
      :message, content_type: :input_csat,
                content_attributes: { 'submitted_values': { 'csat_survey_response': { 'rating': 5, 'feedback_message': 'hello' } } }
    )
  end

  describe '#perform' do
    it 'creates a new csat survey response' do
      csat_survey_response = described_class.new(
        message: message
      ).perform

      expect(csat_survey_response.valid?).to be(true)
    end

    it 'updates the value of csat survey response if response already exists' do
      existing_survey_response = create(:csat_survey_response, message: message)
      csat_survey_response = described_class.new(
        message: message
      ).perform

      expect(csat_survey_response.id).to eq(existing_survey_response.id)
      expect(csat_survey_response.rating).to eq(5)
    end

    context 'when the conversation is unassigned before the contact submits the rating' do
      let(:account) { create(:account) }
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:conversation) { create(:conversation, account: account, assignee: nil) }
      let(:message) do
        create(
          :message, account: account, conversation: conversation, content_type: :input_csat,
                    content_attributes: {
                      'assigned_agent_id': agent.id,
                      'submitted_values': { 'csat_survey_response': { 'rating': 4 } }
                    }
        )
      end

      it 'attributes the response to the agent snapshotted when the survey was sent' do
        csat_survey_response = described_class.new(message: message).perform

        expect(csat_survey_response.assigned_agent).to eq(agent)
      end
    end

    context 'when the survey message predates the assignee snapshot' do
      let(:account) { create(:account) }
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:conversation) { create(:conversation, account: account, assignee: agent) }
      let(:message) do
        create(
          :message, account: account, conversation: conversation, content_type: :input_csat,
                    content_attributes: { 'submitted_values': { 'csat_survey_response': { 'rating': 4 } } }
        )
      end

      it 'falls back to the conversation assignee' do
        csat_survey_response = described_class.new(message: message).perform

        expect(csat_survey_response.assigned_agent).to eq(agent)
      end
    end
  end
end
