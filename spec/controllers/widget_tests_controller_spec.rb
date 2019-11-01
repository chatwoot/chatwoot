require 'rails_helper'

describe WidgetTestsController, type: :controller do
  let(:channel_widget) { create(:channel_widget) }

  describe '#index' do
    it 'renders the page correctly' do
      get :index
      expect(response.status).to eq 200
    end
  end
end
