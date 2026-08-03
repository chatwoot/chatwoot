require 'rails_helper'

describe Whatsapp::InteractiveButtonsPayloadBuilder do
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
               content_type: :interactive_buttons,
               content: 'Choose an option',
               content_attributes: {
                 body_text: 'Please select one:',
                 header: { type: 'image', media_url: 'https://example.com/image.jpg' },
                 footer_text: 'Powered by Chatwoot',
                 buttons: [
                   { id: 'btn_1', text: 'Option A', type: 'reply' },
                   { id: 'btn_2', text: 'Option B', type: 'reply' }
                 ]
               })
      end

      it 'returns correct payload structure', :aggregate_failures do
        payload = described_class.new(message).perform

        expect(payload[:type]).to eq('button')
        expect(payload[:body][:text]).to eq('Please select one:')
        expect(payload[:header][:type]).to eq('image')
        expect(payload[:header][:image][:link]).to eq('https://example.com/image.jpg')
        expect(payload[:footer][:text]).to eq('Powered by Chatwoot')
        expect(payload[:action][:buttons].length).to eq(2)
        expect(payload[:action][:buttons].first[:type]).to eq('reply')
        expect(payload[:action][:buttons].first[:reply][:id]).to eq('btn_1')
        expect(payload[:action][:buttons].first[:reply][:title]).to eq('Option A')
      end
    end

    context 'without header' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_buttons,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 buttons: [{ id: 'btn_1', text: 'Yes', type: 'reply' }]
               })
      end

      it 'omits header from payload' do
        payload = described_class.new(message).perform
        expect(payload[:header]).to be_nil
      end
    end

    context 'with more than 3 buttons' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_buttons,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 buttons: [
                   { id: '1', text: 'A', type: 'reply' },
                   { id: '2', text: 'B', type: 'reply' },
                   { id: '3', text: 'C', type: 'reply' },
                   { id: '4', text: 'D', type: 'reply' }
                 ]
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /at most 3 buttons/)
      end
    end

    context 'with button title exceeding max length' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_buttons,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 buttons: [{ id: '1', text: 'This is a very long button text that exceeds limit', type: 'reply' }]
               })
      end

      it 'truncates button title to 20 characters' do
        payload = described_class.new(message).perform
        expect(payload[:action][:buttons].first[:reply][:title].length).to eq(20)
      end
    end

    context 'with non-WhatsApp inbox' do
      let(:web_inbox) { create(:inbox, account: account) }
      let(:web_conversation) { create(:conversation, inbox: web_inbox, account: account) }
      let(:message) do
        create(:message,
               conversation: web_conversation,
               inbox: web_inbox,
               account: account,
               content_type: :interactive_buttons,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 buttons: [{ id: '1', text: 'A', type: 'reply' }]
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /only supported for WhatsApp/)
      end
    end
  end
end
