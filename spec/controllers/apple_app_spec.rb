require 'rails_helper'

describe '.well-known/apple-app-site-association', type: :request do
  describe 'GET /.well-known/apple-app-site-association' do
    it 'renders the apple-app-site-association file' do
      get '/.well-known/apple-app-site-association'
      expect(response).to have_http_status(:success)
    end
  end
end
