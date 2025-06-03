require 'rails_helper'

describe SurveyHelper do
  describe '.survey_url' do
    let(:conversation_uuid) { 'test-uuid-123' }

    context 'when FRONTEND_URL is set' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://app.chatwoot.com')
      end

      it 'returns the correct survey URL' do
        expected_url = 'https://app.chatwoot.com/survey/responses/test-uuid-123'
        expect(described_class.survey_url(conversation_uuid)).to eq expected_url
      end
    end
  end
end
