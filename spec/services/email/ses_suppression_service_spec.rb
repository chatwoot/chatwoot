require 'rails_helper'

describe Email::SesSuppressionService do
  subject(:service) { described_class.new(client: client) }

  let(:client) { Aws::SESV2::Client.new(stub_responses: true) }
  let(:email) { 'bounced@example.com' }

  describe '.configured?' do
    it 'is true when the role ARN is set' do
      with_modified_env SES_SUPPRESSION_ROLE_ARN: 'arn:aws:iam::123456789012:role/test' do
        expect(described_class.configured?).to be(true)
      end
    end

    it 'is false when the role ARN is not set' do
      with_modified_env SES_SUPPRESSION_ROLE_ARN: nil do
        expect(described_class.configured?).to be(false)
      end
    end
  end

  describe 'region' do
    before do
      stubbed_client = client
      allow(Aws::InstanceProfileCredentials).to receive(:new)
      allow(Aws::AssumeRoleCredentials).to receive(:new)
      allow(Aws::SESV2::Client).to receive(:new).and_return(stubbed_client)
    end

    around do |example|
      with_modified_env(SES_SUPPRESSION_ROLE_ARN: 'arn:aws:iam::123456789012:role/test', SES_SUPPRESSION_REGION: region) { example.run }
    end

    context 'when SES_SUPPRESSION_REGION is set' do
      let(:region) { 'eu-west-1' }

      it 'queries the suppression list in that region' do
        described_class.new.lookup(email)

        expect(Aws::SESV2::Client).to have_received(:new).with(hash_including(region: 'eu-west-1'))
      end
    end

    context 'when SES_SUPPRESSION_REGION is not set' do
      let(:region) { nil }

      it 'defaults to us-east-1' do
        described_class.new.lookup(email)

        expect(Aws::SESV2::Client).to have_received(:new).with(hash_including(region: 'us-east-1'))
      end
    end
  end

  describe '#lookup' do
    it 'returns not_suppressed when SES has no entry' do
      client.stub_responses(:get_suppressed_destination, 'NotFoundException')

      expect(service.lookup(email)).to eq(status: :not_suppressed)
    end

    it 'returns bounce with the suppression time' do
      since = Time.utc(2026, 9, 1, 10, 0, 0)
      client.stub_responses(:get_suppressed_destination, {
                              suppressed_destination: { email_address: email, reason: 'BOUNCE', last_update_time: since }
                            })

      expect(service.lookup(email)).to eq(status: :bounce, since: since)
    end

    it 'returns complaint with the suppression time' do
      since = Time.utc(2026, 9, 2, 10, 0, 0)
      client.stub_responses(:get_suppressed_destination, {
                              suppressed_destination: { email_address: email, reason: 'COMPLAINT', last_update_time: since }
                            })

      expect(service.lookup(email)).to eq(status: :complaint, since: since)
    end

    it 'returns unavailable when SES denies access' do
      client.stub_responses(:get_suppressed_destination, 'AccessDeniedException')

      expect(service.lookup(email)).to eq(status: :unavailable)
    end

    it 'returns unavailable on a network timeout' do
      client.stub_responses(:get_suppressed_destination, Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))

      expect(service.lookup(email)).to eq(status: :unavailable)
    end
  end

  describe '#clear!' do
    it 'deletes the suppressed destination' do
      client.stub_responses(:delete_suppressed_destination, {})

      service.clear!(email)

      expect(client.api_requests.last).to include(operation_name: :delete_suppressed_destination,
                                                  params: { email_address: email })
    end

    it 'raises when SES rejects the delete' do
      client.stub_responses(:delete_suppressed_destination, 'NotFoundException')

      expect { service.clear!(email) }.to raise_error(Aws::SESV2::Errors::NotFoundException)
    end
  end
end
