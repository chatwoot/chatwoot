## the older specs are covered in send in spec/services/whatsapp/send_on_whatsapp_service_spec.rb
require 'rails_helper'

describe Whatsapp::Providers::Whatsapp360DialogService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox)
  end

  describe '#send_message' do
    context 'when message has multiple attachments' do
      it 'sends each attachment as a separate API call and returns the last message id' do
        attachment1 = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment1.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment2 = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment2.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar2.png', content_type: 'image/png')

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .to_return(
            { status: 200, body: { messages: [{ id: 'message_id_1' }] }.to_json, headers: response_headers },
            { status: 200, body: { messages: [{ id: 'message_id_2' }] }.to_json, headers: response_headers }
          )

        expect(service.send_message('+123456789', message)).to eq 'message_id_2'
        expect(WebMock).to have_requested(:post, 'https://waba.360dialog.io/v1/messages').twice
      end

      it 'includes caption only on the first attachment' do
        attachment1 = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment1.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment2 = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment2.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar2.png', content_type: 'image/png')

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        service.send_message('+123456789', message)

        expect(WebMock).to have_requested(:post, 'https://waba.360dialog.io/v1/messages')
          .with(body: hash_including({ image: WebMock::API.hash_including({ caption: message.content }) }))
          .once
        expect(WebMock).to have_requested(:post, 'https://waba.360dialog.io/v1/messages').twice
      end
    end
  end

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
        items = %w[Burito Pasta Sushi Salad].map { |i| { title: i, value: i } }
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select', content_attributes: { items: items })

        expected_action = {
          button: I18n.t('conversations.messages.whatsapp.list_button_label'),
          sections: [{ rows: %w[Burito Pasta Sushi Salad].map { |i| { id: i, title: i } } }]
        }.to_json

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: 'test'
                },
                action: expected_action
              },
              type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end
end
