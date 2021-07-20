require 'rails_helper'

RSpec.describe 'Public Survey Responses API', type: :request do
  let(:account) { create(:account) }

  describe 'GET public/api/v1/survey_responses/{uuid}' do
    let!(:conversation) { create(:conversation, account: account) }
    let!(:message) { create(:message, conversation: conversation, account: account, content_type: 'input_csat') }

    context 'when it is an authenticated user' do
      it 'return the survey response for that conversation' do
        get "/public/api/v1/survey_responses/#{conversation.uuid}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
