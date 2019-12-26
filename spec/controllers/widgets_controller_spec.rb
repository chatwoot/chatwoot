require 'rails_helper'

describe '/widget', type: :request do
  let(:web_widget) { create(:channel_widget) }

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: web_widget.website_token)
      expect(response).to be_successful
    end

    it 'returns 404 when called with out website_token' do
      get widget_url
      expect(response.status).to eq(404)
    end
  end
end
