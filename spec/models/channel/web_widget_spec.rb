# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::WebWidget do
  context 'when
  web widget channel' do
    let!(:channel_widget) { create(:channel_widget) }

    it 'pre chat options' do
      expect(channel_widget.pre_chat_form_options['pre_chat_message']).to eq 'Share your queries or comments here.'
      expect(channel_widget.pre_chat_form_options['pre_chat_fields'].length).to eq 3
    end
  end

  describe '#web_widget_script' do
    let!(:channel_widget) { create(:channel_widget) }

    context 'when ASSET_CDN_HOST is unset' do
      it 'serves sdk.js from BASE_URL and emits no cdnUrl field' do
        with_modified_env ASSET_CDN_HOST: nil, FRONTEND_URL: 'https://app.example.com' do
          script = channel_widget.web_widget_script
          expect(script).to include('var BASE_URL="https://app.example.com"')
          expect(script).to include('g.src=BASE_URL+"/packs/js/sdk.js"')
          expect(script).not_to include('cdnUrl:')
          expect(script).to include("websiteToken: #{channel_widget.website_token.to_json}")
        end
      end
    end

    context 'when ASSET_CDN_HOST is configured' do
      it 'serves sdk.js from the CDN host and emits a cdnUrl field' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com', FRONTEND_URL: 'https://app.example.com' do
          script = channel_widget.web_widget_script
          expect(script).to include('g.src="https://cdn.example.com/packs/js/sdk.js"')
          expect(script).to include('cdnUrl: "https://cdn.example.com"')
          expect(script).to include('baseUrl: BASE_URL')
        end
      end
    end

    context 'with values that require JS escaping' do
      it 'JSON-escapes FRONTEND_URL containing quotes and newlines' do
        with_modified_env ASSET_CDN_HOST: nil, FRONTEND_URL: %(https://app.example.com/"x\n) do
          script = channel_widget.web_widget_script
          expect(script).to include('var BASE_URL="https://app.example.com/\"x\n"')
        end
      end
    end
  end
end
