require 'rails_helper'

describe Whatsapp::InteractiveListPayloadBuilder do
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
               content_type: :interactive_list,
               content: 'Choose from list',
               content_attributes: {
                 body_text: 'Select an option:',
                 header: { type: 'text', text: 'Menu' },
                 footer_text: 'Select one',
                 action: { button_text: 'View options' },
                 sections: [
                   {
                     title: 'Section 1',
                     rows: [
                       { id: 'row_1', title: 'Option A', description: 'First option' },
                       { id: 'row_2', title: 'Option B', description: 'Second option' }
                     ]
                   }
                 ]
               })
      end

      it 'returns correct payload structure' do
        payload = described_class.new(message).perform

        expect(payload[:type]).to eq('list')
        expect(payload[:body][:text]).to eq('Select an option:')
        expect(payload[:header][:type]).to eq('text')
        expect(payload[:header][:text]).to eq('Menu')
        expect(payload[:footer][:text]).to eq('Select one')
        expect(payload[:action][:button]).to eq('View options')
        expect(payload[:action][:sections].length).to eq(1)
        expect(payload[:action][:sections].first[:title]).to eq('Section 1')
        expect(payload[:action][:sections].first[:rows].length).to eq(2)
        expect(payload[:action][:sections].first[:rows].first[:id]).to eq('row_1')
      end
    end

    context 'without header' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_list,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 action: { button_text: 'Options' },
                 sections: [{ title: 'S1', rows: [{ id: '1', title: 'A' }] }]
               })
      end

      it 'omits header from payload' do
        payload = described_class.new(message).perform
        expect(payload[:header]).to be_nil
      end
    end

    context 'without action button_text' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_list,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 action: {},
                 sections: [{ title: 'S1', rows: [{ id: '1', title: 'A' }] }]
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /button_text is required/)
      end
    end

    context 'without sections' do
      let(:message) do
        create(:message,
               conversation: conversation,
               inbox: inbox,
               account: account,
               content_type: :interactive_list,
               content: 'Choose',
               content_attributes: {
                 body_text: 'Select:',
                 action: { button_text: 'Options' },
                 sections: []
               })
      end

      it 'raises error' do
        expect { described_class.new(message).perform }.to raise_error(StandardError, /sections are required/)
      end
    end
  end
end
