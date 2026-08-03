require 'rails_helper'

describe Whatsapp::CarouselPayloadBuilder do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }

  describe '#perform' do
    context 'with valid message containing CTA URL cards' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cards,
               content: 'Browse products',
               content_attributes: {
                 body_text: 'Check these out',
                 items: [
                   {
                     title: 'Product 1',
                     description: 'Great product',
                     media_url: 'https://example.com/img1.jpg',
                     actions: [{ type: 'url', text: 'Buy Now', uri: 'https://example.com/buy/1' }]
                   },
                   {
                     title: 'Product 2',
                     description: 'Another product',
                     media_url: 'https://example.com/img2.jpg',
                     actions: [{ type: 'url', text: 'Buy Now', uri: 'https://example.com/buy/2' }]
                   }
                 ]
               })
      end

      it 'returns correct carousel payload', :aggregate_failures do
        payload = described_class.new(message).perform

        expect(payload[:type]).to eq('carousel')
        expect(payload[:body][:text]).to eq('Check these out')
        expect(payload[:action][:cards].length).to eq(2)

        first_card = payload[:action][:cards].first
        expect(first_card[:card_index]).to eq(0)
        expect(first_card[:type]).to eq('cta_url')
        expect(first_card[:header][:type]).to eq('image')
        expect(first_card[:body][:text]).to include('Product 1')
        expect(first_card[:action][:name]).to eq('cta_url')
        expect(first_card[:action][:parameters][:url]).to eq('https://example.com/buy/1')
      end
    end

    context 'with quick reply cards' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cards,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Pick one',
                 items: [
                   {
                     title: 'Option A',
                     media_url: 'https://example.com/a.jpg',
                     actions: [{ type: 'reply', text: 'Select A', payload: 'opt_a' }]
                   },
                   {
                     title: 'Option B',
                     media_url: 'https://example.com/b.jpg',
                     actions: [{ type: 'reply', text: 'Select B', payload: 'opt_b' }]
                   }
                 ]
               })
      end

      it 'builds quick reply buttons in cards', :aggregate_failures do
        payload = described_class.new(message).perform

        first_card = payload[:action][:cards].first
        expect(first_card[:type]).to eq('button')
        expect(first_card[:action][:buttons].first[:type]).to eq('quick_reply')
        expect(first_card[:action][:buttons].first[:quick_reply][:id]).to eq('opt_a')
      end
    end

    context 'with less than 2 cards' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :cards,
               content: 'Single',
               content_attributes: {
                 body_text: 'Only one',
                 items: [{ title: 'Card 1', actions: [{ type: 'url', text: 'Go', uri: 'https://example.com' }] }]
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /at least 2 cards/)
      end
    end
  end
end
