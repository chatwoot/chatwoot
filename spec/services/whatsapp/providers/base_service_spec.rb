require 'rails_helper'

RSpec.describe Whatsapp::Providers::BaseService do
  let(:whatsapp_channel) { create(:channel_whatsapp) }
  let(:service) { TestWhatsappService.new(whatsapp_channel: whatsapp_channel) }
  let(:message) { create(:message) }

  # Create a test implementation of the base service
  before do
    stub_const('TestWhatsappService', Class.new(described_class) do
      def send_message(_phone_number, _message)
        'test_message_id'
      end

      def send_template(_phone_number, _template_info)
        'test_template_id'
      end

      def sync_templates
        []
      end

      def validate_provider_config?
        true
      end

      def error_message(response)
        response.parsed_response&.dig('error', 'message')
      end
    end)
  end

  describe '#handle_error' do
    context 'when response contains authentication error' do
      let(:auth_error_response) do
        instance_double(
          body: { error: { code: 190, message: 'Invalid OAuth access token' } }.to_json,
          parsed_response: {
            'error' => {
              'code' => 190,
              'message' => 'Invalid OAuth access token',
              'error_subcode' => nil
            }
          }
        )
      end

      it 'calls authorization_error! on the channel' do
        expect(whatsapp_channel).to receive(:authorization_error!)
        service.send(:handle_error, auth_error_response)
      end

      context 'with expired token subcode' do
        let(:expired_token_response) do
          instance_double(
            body: { error: { code: 100, error_subcode: 463, message: 'Token expired' } }.to_json,
            parsed_response: {
              'error' => {
                'code' => 100,
                'error_subcode' => 463,
                'message' => 'Token expired'
              }
            }
          )
        end

        it 'calls authorization_error! on the channel' do
          expect(whatsapp_channel).to receive(:authorization_error!)
          service.send(:handle_error, expired_token_response)
        end
      end

      context 'with invalid token subcode' do
        let(:invalid_token_response) do
          instance_double(
            body: { error: { code: 100, error_subcode: 467, message: 'Invalid token' } }.to_json,
            parsed_response: {
              'error' => {
                'code' => 100,
                'error_subcode' => 467,
                'message' => 'Invalid token'
              }
            }
          )
        end

        it 'calls authorization_error! on the channel' do
          expect(whatsapp_channel).to receive(:authorization_error!)
          service.send(:handle_error, invalid_token_response)
        end
      end
    end

    context 'when response contains non-authentication error' do
      let(:general_error_response) do
        instance_double(
          body: { error: { code: 100, message: 'General error' } }.to_json,
          parsed_response: {
            'error' => {
              'code' => 100,
              'message' => 'General error'
            }
          }
        )
      end

      it 'does not call authorization_error!' do
        expect(whatsapp_channel).not_to receive(:authorization_error!)
        service.send(:handle_error, general_error_response)
      end
    end

    context 'when response has no error structure' do
      let(:empty_response) do
        instance_double(
          body: '{}',
          parsed_response: {}
        )
      end

      it 'does not call authorization_error!' do
        expect(whatsapp_channel).not_to receive(:authorization_error!)
        service.send(:handle_error, empty_response)
      end
    end

    context 'when message is present' do
      let(:error_response) do
        instance_double(
          body: { error: { message: 'Test error' } }.to_json,
          parsed_response: { 'error' => { 'message' => 'Test error' } }
        )
      end

      before do
        service.instance_variable_set(:@message, message)
      end

      it 'updates message with error details' do
        service.send(:handle_error, error_response)

        expect(message.external_error).to eq('Test error')
        expect(message.status).to eq('failed')
      end
    end
  end

  describe '#process_response' do
    context 'when response is successful' do
      let(:success_response) do
        instance_double(
          success?: true,
          parsed_response: {
            'messages' => [{ 'id' => 'message_123' }]
          }
        )
      end

      it 'returns the message id' do
        result = service.send(:process_response, success_response)
        expect(result).to eq('message_123')
      end
    end

    context 'when response contains error' do
      let(:error_response) do
        instance_double(
          success?: true,
          body: { error: { message: 'Error occurred' } }.to_json,
          parsed_response: {
            'error' => { 'message' => 'Error occurred' }
          }
        )
      end

      it 'handles the error and returns nil' do
        expect(service).to receive(:handle_error).with(error_response)
        result = service.send(:process_response, error_response)
        expect(result).to be_nil
      end
    end

    context 'when response is not successful' do
      let(:failed_response) do
        instance_double(
          success?: false,
          body: 'Failed',
          parsed_response: {}
        )
      end

      it 'handles the error and returns nil' do
        expect(service).to receive(:handle_error).with(failed_response)
        result = service.send(:process_response, failed_response)
        expect(result).to be_nil
      end
    end
  end
end
