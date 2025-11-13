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

    it 'dispatches csat_survey_response.created event' do
      expect(Rails.configuration.dispatcher).to receive(:dispatch)
        .with(Events::Types::CSAT_SURVEY_RESPONSE_CREATED, anything, hash_including(:csat_survey_response, :message))

      described_class.new(message: message).perform
    end
  end
end
