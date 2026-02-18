require 'rails_helper'

describe Whatsapp::Ycloud::ProfileService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:phone_number_id) { 'pn_001' }

  describe '#list_phone_numbers' do
    it 'lists phone numbers' do
      stub = stub_request(:get, "#{api_base}/whatsapp/phoneNumbers?page=1&limit=20")
        .to_return(status: 200, body: { items: [], total: 0 }.to_json, headers: headers)

      service.list_phone_numbers
      expect(stub).to have_been_requested
    end
  end

  describe '#get_phone_number' do
    it 'retrieves phone number by ID' do
      stub = stub_request(:get, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}")
        .to_return(status: 200, body: { id: phone_number_id }.to_json, headers: headers)

      service.get_phone_number(phone_number_id)
      expect(stub).to have_been_requested
    end
  end

  describe '#get_business_profile' do
    it 'retrieves business profile' do
      stub = stub_request(:get, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}/profile")
        .to_return(status: 200, body: { about: 'Test business' }.to_json, headers: headers)

      response = service.get_business_profile(phone_number_id)
      expect(stub).to have_been_requested
      expect(response.parsed_response['about']).to eq('Test business')
    end
  end

  describe '#update_business_profile' do
    it 'updates business profile' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}/profile")
        .with(body: hash_including({ 'about' => 'Updated' }))
        .to_return(status: 200, body: { about: 'Updated' }.to_json, headers: headers)

      service.update_business_profile(phone_number_id, about: 'Updated')
      expect(stub).to have_been_requested
    end
  end

  describe '#update_display_name' do
    it 'submits display name change request' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}/display-name")
        .with(body: { displayName: 'New Name' }.to_json)
        .to_return(status: 200, body: '{}', headers: headers)

      service.update_display_name(phone_number_id, 'New Name')
      expect(stub).to have_been_requested
    end
  end

  describe '#get_commerce_settings' do
    it 'retrieves commerce settings' do
      stub = stub_request(:get, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}/commerce-settings")
        .to_return(status: 200, body: { isCatalogVisible: true }.to_json, headers: headers)

      response = service.get_commerce_settings(phone_number_id)
      expect(stub).to have_been_requested
      expect(response.parsed_response['isCatalogVisible']).to be true
    end
  end

  describe '#update_commerce_settings' do
    it 'updates commerce settings' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/phoneNumbers/#{phone_number_id}/commerce-settings")
        .with(body: hash_including({ 'isCartEnabled' => false }))
        .to_return(status: 200, body: '{}', headers: headers)

      service.update_commerce_settings(phone_number_id, isCartEnabled: false)
      expect(stub).to have_been_requested
    end
  end
end
