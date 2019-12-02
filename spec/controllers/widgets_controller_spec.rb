require 'rails_helper'

describe '/widget', type: :request do
  let(:channel_widget) { create(:channel_widget) }

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: channel_widget.website_token)
      expect(response).to be_successful
    end

    it 'raises when called with website_token' do
      expect { get widget_url }.to raise_exception ActiveRecord::RecordNotFound
    end
  end
end
