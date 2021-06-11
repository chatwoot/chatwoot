require 'rails_helper'

describe '/app/login', type: :request do
  context 'without DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      get '/app/login'
      expect(response).to have_http_status(:success)
    end
  end

  context 'with DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      ENV['DEFAULT_LOCALE'] = 'pt_BR'
      get '/app/login'
      expect(response).to have_http_status(:success)
      expect(response.body).to include "selectedLocale: 'pt_BR'"
      ENV['DEFAULT_LOCALE'] = 'en'
    end
  end

  # Routes are loaded once on app start
  # hence Rails.application.reload_routes! is used in this spec
  # ref : https://stackoverflow.com/a/63584877/939299
  context 'with CW_API_ONLY_SERVER true' do
    it 'returns 404' do
      ENV['CW_API_ONLY_SERVER'] = 'true'
      Rails.application.reload_routes!
      get '/app/login'
      expect(response).to have_http_status(:not_found)
      ENV['CW_API_ONLY_SERVER'] = nil
      Rails.application.reload_routes!
    end
  end
end
