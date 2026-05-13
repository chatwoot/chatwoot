require 'rails_helper'

# Simulate the prepend_mod_with overlay for testing.
test_klass = Class.new(Onboarding::WebWidgetCreationService) do
  prepend Enterprise::Onboarding::WebWidgetCreationService
end

RSpec.describe Enterprise::Onboarding::WebWidgetCreationService do
  let(:account) do
    create(:account, name: 'Acme Inc', domain: 'acme.com', custom_attributes: {
             'brand_info' => { 'slogan' => 'Fallback slogan', 'description' => 'Fallback description' }
           })
  end
  let(:user) { create(:user) }
  let(:service) { test_klass.new(account, user) }

  before { create(:account_user, account: account, user: user, role: :administrator) }

  describe '#welcome_tagline_text via #perform' do
    let(:llm_double) { instance_double(Captain::Llm::WidgetTaglineService) }

    before do
      allow(Captain::Llm::WidgetTaglineService).to receive(:new).and_return(llm_double)
    end

    context 'when the LLM returns a tagline' do
      before { allow(llm_double).to receive(:perform).and_return(message: '  LLM tagline  ') }

      it 'uses the (stripped) LLM-generated tagline' do
        expect(service.perform.channel.welcome_tagline).to eq('LLM tagline')
      end
    end

    context 'when the LLM returns a blank message' do
      before { allow(llm_double).to receive(:perform).and_return(message: '') }

      it 'falls back to brand_info text' do
        expect(service.perform.channel.welcome_tagline).to eq('Fallback slogan')
      end
    end

    context 'when the LLM returns an error response' do
      before { allow(llm_double).to receive(:perform).and_return(error: 'LLM timeout', error_code: 500) }

      it 'falls back to brand_info text' do
        expect(service.perform.channel.welcome_tagline).to eq('Fallback slogan')
      end
    end

    context 'when the LLM raises an exception' do
      before { allow(llm_double).to receive(:perform).and_raise(StandardError, 'boom') }

      it 'still creates the widget with brand_info fallback (no transaction rollback)' do
        expect { service.perform }.to change(Channel::WebWidget, :count).by(1)
        expect(service.perform.channel.welcome_tagline).to eq('Fallback slogan')
      end
    end
  end
end
