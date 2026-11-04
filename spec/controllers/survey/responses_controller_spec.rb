require 'rails_helper'

describe '/survey/responses', type: :request do
  describe 'GET /survey/responses/:id' do
    it 'does not set the session cookie' do
      previous = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      get survey_response_url(id: SecureRandom.uuid)

      expect(response).to have_http_status(:ok)
      expect(response.headers['Set-Cookie'].to_s).not_to include('_chatwoot_session')
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end
end
