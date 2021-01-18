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
end
