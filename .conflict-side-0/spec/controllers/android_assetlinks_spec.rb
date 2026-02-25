require 'rails_helper'

describe '.well-known/assetlinks.json', type: :request do
  describe 'GET /.well-known/assetlinks.json' do
    it 'successfully retrieves assetlinks.json file' do
      get '/.well-known/assetlinks.json'
      expect(response).to have_http_status(:success)
    end
  end
end
