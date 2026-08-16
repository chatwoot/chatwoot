require 'rails_helper'
require_relative '../../../deployment/myinvest/scripts/cutover-whatsapp'

describe Myinvest::WhatsappCutover::Wrapper do
  subject(:wrapper) { described_class.new(env) }

  let(:env) do
    {
      'CUTOVER_CONFIRMATION' => 'cutover-whatsapp:legacy_academy:+491234567890',
      'CUTOVER_TENANT' => 'legacy_academy',
      'WHATSAPP_PHONE_NUMBER' => '+491234567890',
      'WHATSAPP_PHONE_NUMBER_ID' => '1234567890',
      'WHATSAPP_WABA_ID' => '9876543210',
      'WHATSAPP_ACCESS_TOKEN' => 'super-secret-access-token',
      'WHATSAPP_APP_SECRET' => 'super-secret-app-secret',
      'HUBSPOT_ACCESS_TOKEN' => 'super-secret-hubspot-token',
      'HUBSPOT_CHANNEL_ACCOUNT_ID' => 'hubspot-channel-account-1'
    }
  end

  describe '#run' do
    before do
      checker = instance_double(Myinvest::WhatsappCutover::HubspotChannelChecker, cutover_allowed?: true)
      allow(Myinvest::WhatsappCutover::HubspotChannelChecker).to receive(:new).and_return(checker)
      allow(wrapper).to receive(:run_rails_provisioner!).and_return(true)
    end

    it 'requires an exact confirmation' do
      env['CUTOVER_CONFIRMATION'] = 'wrong'
      expect { wrapper.run }.to raise_error(/Confirmation mismatch/)
    end

    it 'rejects when required variables are missing' do
      env.delete('WHATSAPP_ACCESS_TOKEN')
      expect { wrapper.run }.to raise_error(/Missing required variables/)
    end

    it 'rejects when HubSpot channel account is still active' do
      checker = instance_double(Myinvest::WhatsappCutover::HubspotChannelChecker, cutover_allowed?: false)
      allow(Myinvest::WhatsappCutover::HubspotChannelChecker).to receive(:new).and_return(checker)
      expect { wrapper.run }.to raise_error(/HubSpot channel account is still active or authorized/)
    end

    it 'invokes the Rails provisioner when checks pass' do
      expect(wrapper).to receive(:run_rails_provisioner!)
      wrapper.run
    end

    it 'skips the Rails provisioner in dry-run mode' do
      env['DRY_RUN'] = 'true'
      expect(wrapper).not_to receive(:run_rails_provisioner!)
      wrapper.run
    end

    it 'does not pass secret values through argv to the provisioner' do
      captured = nil
      allow(wrapper).to receive(:system) do |*_args|
        # The first positional argument when calling system(env_hash, *command) is the env hash.
        captured = _args[1..]
        true
      end
      allow(wrapper).to receive(:run_rails_provisioner!).and_call_original

      wrapper.run

      argv = Array(captured).flatten
      expect(argv).to include('-e')
      expect(argv).not_to include('WHATSAPP_ACCESS_TOKEN=super-secret-access-token')
      expect(argv).not_to include('WHATSAPP_APP_SECRET=super-secret-app-secret')
      expect(argv.join(' ')).not_to include('super-secret')
    end
  end

  describe Myinvest::WhatsappCutover::HubspotChannelChecker do
    subject(:checker) { described_class.new(access_token: 'token', channel_account_id: 'account-1') }

    let(:base_uri) { 'https://api.hubapi.com' }

    it 'rejects empty access token' do
      expect { described_class.new(access_token: '', channel_account_id: 'account-1') }
        .to raise_error(ArgumentError, /access token is required/)
    end

    it 'rejects empty channel account id' do
      expect { described_class.new(access_token: 'token', channel_account_id: '') }
        .to raise_error(ArgumentError, /channel account ID is required/)
    end

    it 'rejects non-https base uri' do
      expect { described_class.new(access_token: 'token', channel_account_id: 'account-1', base_uri: 'http://api.hubapi.com') }
        .to raise_error(ArgumentError, /HubSpot endpoint must use HTTPS/)
    end

    it 'fails closed when the channel account is absent' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: { 'results' => [] }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/channel account not found/)
    end

    it 'allows cutover when the channel account is inactive and unauthorized' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [
            { 'id' => 'other-account', 'active' => true, 'authorized' => true },
            { 'id' => 'account-1', 'active' => false, 'authorized' => false }
          ]
        }.to_json)

      expect(checker.cutover_allowed?).to be(true)
    end

    it 'rejects cutover when the channel account is active' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'account-1', 'active' => true, 'authorized' => false }]
        }.to_json)

      expect(checker.cutover_allowed?).to be(false)
    end

    it 'rejects cutover when the channel account is authorized' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'account-1', 'active' => false, 'authorized' => true }]
        }.to_json)

      expect(checker.cutover_allowed?).to be(false)
    end

    it 'paginates through HubSpot channel accounts' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts\?limit=100$})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'page-one', 'active' => false, 'authorized' => false }],
          'paging' => { 'next' => { 'after' => 'page2token' } }
        }.to_json)
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts\?.*after=page2token.*})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'account-1', 'active' => false, 'authorized' => false }]
        }.to_json)

      expect(checker.cutover_allowed?).to be(true)
    end

    it 'raises on HubSpot API errors' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 401, body: '{}')

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot API returned HTTP 401/)
    end
  end
end
