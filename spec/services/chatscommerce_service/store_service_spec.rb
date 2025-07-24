require 'rails_helper'

RSpec.describe ChatscommerceService::StoreService do
  let(:service) { described_class.new }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:api_url) { 'https://test.chatscommerce.com' }
  let(:store_id) { SecureRandom.uuid }

  before do
    allow(service).to receive(:chatscommerce_api_url).and_return(api_url)
    account.update!(custom_attributes: { store_id: store_id })
  end

  describe '#create_store' do
    let(:store_data) do
      {
        store: {
          id: store_id,
          name: account.name,
          email: user.email,
          phone: '',
          useCases: "#{account.name}UseCases",
          ecommercePlatform: 'shopify',
          isActive: true
        }
      }
    end
    let(:success_response) { { 'store' => { 'id' => store_id } }.to_json }

    context 'when the API call is successful' do
      before do
        stub_request(:put, "#{api_url}/api/stores/")
          .with(body: store_data.to_json)
          .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the parsed response' do
        response = service.create_store(account, user.email)
        expect(response).to eq(JSON.parse(success_response))
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:put, "#{api_url}/api/stores/")
          .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
      end

      it 'raises a StoreError' do
        expect do
          service.create_store(account, user.email)
        end.to raise_error(ChatscommerceService::StoreService::StoreError, /Store cannot be created: 500/)
      end
    end
  end
end