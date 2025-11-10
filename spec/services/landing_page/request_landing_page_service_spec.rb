# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LandingPage::RequestLandingPageService do
  let(:account) { create(:account) }
  let(:channel_widget) do
    create(:channel_widget,
           account: account,
           auto_generate_landing_page: true,
           landing_page_description: 'Test landing page description')
  end
  let(:inbox) { channel_widget.inbox }
  let(:service) { described_class.new(inbox) }
  let(:landing_page_endpoint) { 'https://api.example.com/landing-page' }
  let(:landing_page_url) { 'https://example.com/landing-page/abc123' }
  let(:mock_response) { instance_double(HTTParty::Response) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LANDING_PAGE_GENERATION_ENDPOINT', nil).and_return(landing_page_endpoint)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', '').and_return('https://app.chatwoot.com')
  end

  describe '#perform' do
    context 'when request is successful' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:parsed_response).and_return({ 'url' => landing_page_url })
        allow(Rails.logger).to receive(:info)
      end

      it 'requests landing page URL and updates the channel' do
        service.perform

        expect(HTTParty).to have_received(:post).with(
          landing_page_endpoint,
          {
            body: {
              inbox_name: inbox.name,
              website_url: channel_widget.website_url,
              website_token: channel_widget.website_token,
              landing_page_description: channel_widget.landing_page_description,
              frontend_url: 'https://app.chatwoot.com'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' },
            timeout: 60
          }
        )
        expect(channel_widget.reload.landing_page_url).to eq(landing_page_url)
        expect(Rails.logger).to have_received(:info).with(
          "[REQUEST_LANDING_PAGE] Successfully updated landing page URL for inbox #{inbox.id}"
        )
      end
    end

    context 'when API request fails' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
        allow(mock_response).to receive(:success?).and_return(false)
        allow(mock_response).to receive(:code).and_return(500)
        allow(mock_response).to receive(:body).and_return('Internal Server Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and raises an exception' do
        expect { service.perform }.to raise_error(/Landing page API request failed: 500/)

        expect(Rails.logger).to have_received(:error).with(
          /\[REQUEST_LANDING_PAGE\] Landing page API request failed: 500/
        )
      end
    end

    context 'when response is missing landing_page_url' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:parsed_response).and_return({ 'some_other_field' => 'value' })
      end

      it 'raises an exception' do
        expect { service.perform }.to raise_error('Landing page URL not found in response')
      end
    end

    context 'when landing_page_url is blank in response' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:parsed_response).and_return({ 'url' => '' })
      end

      it 'raises an exception' do
        expect { service.perform }.to raise_error('Landing page URL not found in response')
      end
    end

    context 'when HTTParty request times out' do
      before do
        allow(HTTParty).to receive(:post).and_raise(Net::ReadTimeout)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and raises an exception' do
        expect { service.perform }.to raise_error(Net::ReadTimeout)

        expect(Rails.logger).to have_received(:error).with(
          /\[REQUEST_LANDING_PAGE\] Error requesting landing page:/
        )
      end
    end
  end

  describe 'validation' do
    context 'when inbox is nil' do
      it 'raises an error' do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'when channel is not a WebWidget' do
      let(:api_channel) { create(:channel_api, account: account) }
      let(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
      let(:service) { described_class.new(api_inbox) }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Channel must be a WebWidget')
      end
    end

    context 'when landing page endpoint is not configured' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('LANDING_PAGE_GENERATION_ENDPOINT', nil).and_return(nil)
      end

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Landing page endpoint URL is not configured')
      end
    end

    context 'when landing page endpoint is blank' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('LANDING_PAGE_GENERATION_ENDPOINT', nil).and_return('')
      end

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Landing page endpoint URL is not configured')
      end
    end
  end

  describe 'private methods' do
    describe '#request_payload' do
      it 'includes all required fields' do
        expected_payload = {
          inbox_name: inbox.name,
          website_url: channel_widget.website_url,
          website_token: channel_widget.website_token,
          landing_page_description: channel_widget.landing_page_description,
          frontend_url: 'https://app.chatwoot.com'
        }

        actual_payload = service.send(:request_payload)

        expect(actual_payload).to eq(expected_payload)
      end
    end
  end
end
