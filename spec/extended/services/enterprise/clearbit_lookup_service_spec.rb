require 'rails_helper'

RSpec.describe Enterprise::ClearbitLookupService do
  describe '.lookup' do
    let(:email) { 'test@example.com' }
    let(:api_key) { 'clearbit_api_key' }
    let(:clearbit_endpoint) { described_class::CLEARBIT_ENDPOINT }
    let(:response_body) { build(:clearbit_combined_response) }

    context 'when Clearbit is enabled' do
      before do
        stub_request(:get, "#{clearbit_endpoint}?email=#{email}")
          .with(headers: { 'Authorization' => "Bearer #{api_key}" })
          .to_return(status: 200, body: response_body, headers: { 'content-type' => ['application/json'] })
      end

      context 'when the API is working as expected' do
        it 'returns the person and company information' do
          with_modified_env CLEARBIT_API_KEY: api_key do
            result = described_class.lookup(email)

            expect(result).to eq({
                                   :avatar => 'https://example.com/avatar.png',
                                   :company_name => 'Doe Inc.',
                                   :company_size => '1-10',
                                   :industry => 'Software',
                                   :logo => nil,
                                   :name => 'John Doe',
                                   :timezone => 'Asia/Kolkata'
                                 })
          end
        end
      end

      context 'when the API returns an error' do
        before do
          stub_request(:get, "#{clearbit_endpoint}?email=#{email}")
            .with(headers: { 'Authorization' => "Bearer #{api_key}" })
            .to_return(status: 404, body: '', headers: {})
        end

        it 'logs the error and returns nil' do
          with_modified_env CLEARBIT_API_KEY: api_key do
            expect(Rails.logger).to receive(:error)
            expect(described_class.lookup(email)).to be_nil
          end
        end
      end
    end

    context 'when Clearbit is not enabled' do
      before do
        GlobalConfig.clear_cache
      end

      it 'returns nil without making an API call' do
        with_modified_env CLEARBIT_API_KEY: nil do
          expect(Net::HTTP).not_to receive(:start)
          expect(described_class.lookup(email)).to be_nil
        end
      end
    end
  end
end
