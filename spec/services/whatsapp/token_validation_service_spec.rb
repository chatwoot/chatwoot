require 'rails_helper'

describe Whatsapp::TokenValidationService do
  let(:access_token) { 'test_access_token' }
  let(:waba_id) { 'test_waba_id' }
  let(:service) { described_class.new(access_token, waba_id) }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

  before do
    allow(Whatsapp::FacebookApiClient).to receive(:new).with(access_token).and_return(api_client)
  end

  describe '#perform' do
    context 'when token has access to WABA' do
      let(:debug_response) do
        {
          'data' => {
            'granular_scopes' => [
              {
                'scope' => 'whatsapp_business_management',
                'target_ids' => [waba_id, 'another_waba_id']
              }
            ]
          }
        }
      end

      before do
        allow(api_client).to receive(:debug_token).with(access_token).and_return(debug_response)
      end

      it 'validates successfully' do
        expect { service.perform }.not_to raise_error
      end
    end

    context 'when token does not have access to WABA' do
      let(:debug_response) do
        {
          'data' => {
            'granular_scopes' => [
              {
                'scope' => 'whatsapp_business_management',
                'target_ids' => ['different_waba_id']
              }
            ]
          }
        }
      end

      before do
        allow(api_client).to receive(:debug_token).with(access_token).and_return(debug_response)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Token does not have access to WABA/)
      end
    end

    context 'when no WABA scope is found' do
      let(:debug_response) do
        {
          'data' => {
            'granular_scopes' => [
              {
                'scope' => 'some_other_scope',
                'target_ids' => ['some_id']
              }
            ]
          }
        }
      end

      before do
        allow(api_client).to receive(:debug_token).with(access_token).and_return(debug_response)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error('No WABA scope found in token')
      end
    end

    context 'when access_token is blank' do
      let(:access_token) { '' }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Access token is required')
      end
    end

    context 'when waba_id is blank' do
      let(:waba_id) { '' }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'WABA ID is required')
      end
    end
  end
end
