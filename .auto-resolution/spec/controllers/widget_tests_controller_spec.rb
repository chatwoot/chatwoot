require 'rails_helper'

describe '/widget_tests', type: :request do
  before do
    create(:channel_widget)
  end

  describe 'GET /widget_tests' do
    it 'renders the page correctly' do
      get widget_tests_url
      expect(response).to be_successful
    end
  end
end
