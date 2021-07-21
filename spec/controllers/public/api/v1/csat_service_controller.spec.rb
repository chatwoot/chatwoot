require 'rails_helper'

RSpec.describe 'Public Survey Responses API', type: :request do
  describe 'GET public/api/v1/csat_service/{uuid}' do
    context 'when it is an authenticated user' do
      it 'return the survey response for that conversation' do
        conversation = create(:conversation)
        create(:message, conversation: conversation, content_type: 'input_csat')

        get "/public/api/v1/csat_service/#{conversation.uuid}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
