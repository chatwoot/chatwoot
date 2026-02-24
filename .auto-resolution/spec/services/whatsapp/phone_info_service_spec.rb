require 'rails_helper'

describe Whatsapp::PhoneInfoService do
  let(:waba_id) { 'test_waba_id' }
  let(:phone_number_id) { 'test_phone_number_id' }
  let(:access_token) { 'test_access_token' }
  let(:service) { described_class.new(waba_id, phone_number_id, access_token) }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

  before do
    allow(Whatsapp::FacebookApiClient).to receive(:new).with(access_token).and_return(api_client)
  end

  describe '#perform' do
    let(:phone_response) do
      {
        'data' => [
          {
            'id' => phone_number_id,
            'display_phone_number' => '1234567890',
            'verified_name' => 'Test Business',
            'code_verification_status' => 'VERIFIED'
          }
        ]
      }
    end

    context 'when all parameters are valid' do
      before do
        allow(api_client).to receive(:fetch_phone_numbers).with(waba_id).and_return(phone_response)
      end

      it 'returns formatted phone info' do
        result = service.perform
        expect(result).to eq({
                               phone_number_id: phone_number_id,
                               phone_number: '+1234567890',
                               verified: true,
                               business_name: 'Test Business'
                             })
      end
    end

    context 'when phone_number_id is not provided' do
      let(:phone_number_id) { nil }
      let(:phone_response) do
        {
          'data' => [
            {
              'id' => 'first_phone_id',
              'display_phone_number' => '1234567890',
              'verified_name' => 'Test Business',
              'code_verification_status' => 'VERIFIED'
            }
          ]
        }
      end

      before do
        allow(api_client).to receive(:fetch_phone_numbers).with(waba_id).and_return(phone_response)
      end

      it 'uses the first available phone number' do
        result = service.perform
        expect(result[:phone_number_id]).to eq('first_phone_id')
      end
    end

    context 'when specific phone_number_id is not found' do
      let(:phone_number_id) { 'different_id' }
      let(:phone_response) do
        {
          'data' => [
            {
              'id' => 'available_phone_id',
              'display_phone_number' => '9876543210',
              'verified_name' => 'Different Business',
              'code_verification_status' => 'VERIFIED'
            }
          ]
        }
      end

      before do
        allow(api_client).to receive(:fetch_phone_numbers).with(waba_id).and_return(phone_response)
      end

      it 'uses the first available phone number as fallback' do
        result = service.perform
        expect(result[:phone_number_id]).to eq('available_phone_id')
        expect(result[:phone_number]).to eq('+9876543210')
      end
    end

    context 'when no phone numbers are available' do
      let(:phone_response) { { 'data' => [] } }

      before do
        allow(api_client).to receive(:fetch_phone_numbers).with(waba_id).and_return(phone_response)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/No phone numbers found for WABA/)
      end
    end

    context 'when waba_id is blank' do
      let(:waba_id) { '' }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'WABA ID is required')
      end
    end

    context 'when access_token is blank' do
      let(:access_token) { '' }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Access token is required')
      end
    end

    context 'when phone number has special characters' do
      let(:phone_response) do
        {
          'data' => [
            {
              'id' => phone_number_id,
              'display_phone_number' => '+1 (234) 567-8900',
              'verified_name' => 'Test Business',
              'code_verification_status' => 'VERIFIED'
            }
          ]
        }
      end

      before do
        allow(api_client).to receive(:fetch_phone_numbers).with(waba_id).and_return(phone_response)
      end

      it 'sanitizes the phone number' do
        result = service.perform
        expect(result[:phone_number]).to eq('+12345678900')
      end
    end
  end
end
