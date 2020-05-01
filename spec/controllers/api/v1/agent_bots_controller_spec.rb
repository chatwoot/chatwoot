require 'rails_helper'

RSpec.describe 'Profile API', type: :request do
  let!(:agent_bot1) { create(:agent_bot) }
  let!(:agent_bot2) { create(:agent_bot) }

  describe 'GET /api/v1/agent_bots' do
    it 'returns all the agent bots in the system' do
      get '/api/v1/agent_bots',
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).to include(agent_bot1.name)
      expect(response.body).to include(agent_bot2.name)
    end
  end
end
