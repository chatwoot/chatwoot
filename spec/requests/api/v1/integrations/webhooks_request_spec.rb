require 'rails_helper'

RSpec.describe 'Api::V1::Integrations::Webhooks', type: :request do
  describe 'POST /api/v1/integrations/webhooks' do
    it 'consumes webhook' do
      builder = Integrations::Slack::IncomingMessageBuilder.new({})
      expect(builder).to receive(:perform).and_return(true)

      expect(Integrations::Slack::IncomingMessageBuilder).to receive(:new).and_return(builder)

      post '/api/v1/integrations/webhooks', params: {}
      expect(response).to have_http_status(:success)
    end
  end
end
