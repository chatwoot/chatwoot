require 'rails_helper'

describe Whatsapp::CtaUrlPayloadBuilder do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }

  describe '#perform' do
    context 'with valid message' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cta_url,
               content: 'Visit our site',
               content_attributes: {
                 body_text: 'Check out our website',
                 header: { type: 'image', media_url: 'https://example.com/banner.jpg' },
                 footer_text: 'Click below',
                 action: { text: 'Visit Now', uri: 'https://example.com' }
               })
      end

      it 'returns correct payload structure', :aggregate_failures do
        payload = described_class.new(message).perform

        expect(payload[:type]).to eq('cta_url')
        expect(payload[:body][:text]).to eq('Check out our website')
        expect(payload[:header][:type]).to eq('image')
        expect(payload[:header][:image][:link]).to eq('https://example.com/banner.jpg')
        expect(payload[:footer][:text]).to eq('Click below')
        expect(payload[:action][:name]).to eq('cta_url')
        expect(payload[:action][:parameters][:display_text]).to eq('Visit Now')
        expect(payload[:action][:parameters][:url]).to eq('https://example.com')
      end
    end

    context 'without header' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cta_url,
               content: 'Visit',
               content_attributes: {
                 body_text: 'Go to site',
                 action: { text: 'Click', uri: 'https://example.com' }
               })
      end

      it 'omits header and footer from payload' do
        payload = described_class.new(message).perform
        expect(payload[:header]).to be_nil
        expect(payload[:footer]).to be_nil
      end
    end

    context 'without action text' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cta_url,
               content: 'Visit',
               content_attributes: {
                 body_text: 'Go',
                 action: { uri: 'https://example.com' }
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /action text is required/)
      end
    end

    context 'without action uri' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cta_url,
               content: 'Visit',
               content_attributes: {
                 body_text: 'Go',
                 action: { text: 'Click' }
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /action uri is required/)
      end
    end
  end
end
