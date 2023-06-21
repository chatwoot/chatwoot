## the older specs are covered in send in spec/services/whatsapp/send_on_whatsapp_service_spec.rb
require 'rails_helper'

describe Whatsapp::Providers::Whatsapp360DialogService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#sync_templates' do
    context 'when called' do
      it 'updates message_templates_last_updated even when template request fails' do
        stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
          .to_return(status: 401)

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        subject.sync_templates
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
      end
    end
  end

  describe '#send_interactive message' do
    context 'when called' do
      it 'calls message endpoints with button payload when number of items is less than or equal to 3' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                   content_attributes: {
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' }
                                     ]
                                   })
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              to: '+123456789',
              interactive: {
                type: 'button',
                body: {
                  text: 'test'
                },
                action: '{"buttons":[{"type":"reply","reply":{"id":"Burito","title":"Burito"}},{"type":"reply",' \
                        '"reply":{"id":"Pasta","title":"Pasta"}},{"type":"reply","reply":{"id":"Sushi","title":"Sushi"}}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints with list payload when number of items is greater than 3' do
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select',
                                   content_attributes: {
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' },
                                       { title: 'Salad', value: 'Salad' }
                                     ]
                                   })
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: 'test'
                },
                action: '{"button":"Choose an item","sections":[{"rows":[{"id":"Burito","title":"Burito"},' \
                        '{"id":"Pasta","title":"Pasta"},{"id":"Sushi","title":"Sushi"},{"id":"Salad","title":"Salad"}]}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end
end
