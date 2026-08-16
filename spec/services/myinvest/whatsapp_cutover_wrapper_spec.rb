require 'rails_helper'
require_relative '../../../deployment/myinvest/scripts/cutover-whatsapp'
require_relative '../../../deployment/myinvest/bootstrap/cutover_whatsapp'

describe Myinvest::WhatsappCutover::Wrapper do
  subject(:wrapper) { described_class.new(env) }

  let(:env) do
    {
      'CUTOVER_CONFIRMATION' => 'cutover-whatsapp:legacy_academy:+491234567890',
      'CUTOVER_TENANT' => 'legacy_academy',
      'WHATSAPP_PHONE_NUMBER' => '+491234567890',
      'WHATSAPP_PHONE_NUMBER_ID' => '1234567890',
      'WHATSAPP_WABA_ID' => '9876543210',
      'WHATSAPP_BUSINESS_PORTFOLIO_ID' => '1122334455',
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

    def capture_output
      old_stdout = $stdout
      old_stderr = $stderr
      $stdout = StringIO.new
      $stderr = StringIO.new
      yield
      [$stdout.string, $stderr.string, nil]
    rescue StandardError => e
      [$stdout.string, $stderr.string, e]
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    def sensitive_values
      [
        env['CUTOVER_CONFIRMATION'],
        env['CUTOVER_TENANT'],
        env['WHATSAPP_PHONE_NUMBER'],
        env['WHATSAPP_PHONE_NUMBER_ID'],
        env['WHATSAPP_WABA_ID'],
        env['WHATSAPP_BUSINESS_PORTFOLIO_ID'],
        env['WHATSAPP_ACCESS_TOKEN'],
        env['WHATSAPP_APP_SECRET'],
        env['HUBSPOT_ACCESS_TOKEN'],
        env['HUBSPOT_CHANNEL_ACCOUNT_ID']
      ].compact
    end

    it 'requires an exact confirmation' do
      env['CUTOVER_CONFIRMATION'] = 'wrong'
      expect { wrapper.run }.to raise_error(/Confirmation mismatch/)
    end

    it 'does not include the expected confirmation in mismatch errors' do
      env['CUTOVER_CONFIRMATION'] = 'wrong'
      expect { wrapper.run }.to raise_error do |error|
        expect(error.message).not_to include(env['WHATSAPP_PHONE_NUMBER'])
        expect(error.message).not_to include(env['CUTOVER_TENANT'])
      end
    end

    it 'rejects when required variables are missing' do
      env.delete('WHATSAPP_ACCESS_TOKEN')
      expect { wrapper.run }.to raise_error(/Missing required variables/)
    end

    it 'rejects when HubSpot channel account is still active or authorized' do
      checker = instance_double(Myinvest::WhatsappCutover::HubspotChannelChecker, cutover_allowed?: false)
      allow(Myinvest::WhatsappCutover::HubspotChannelChecker).to receive(:new).and_return(checker)
      expect { wrapper.run }.to raise_error(/HubSpot channel account is still active or authorized/)
    end

    it 'invokes the Rails provisioner when checks pass' do
      expect(wrapper).to receive(:run_rails_provisioner!)
      wrapper.run
    end

    it 'invokes the Rails provisioner with DRY_RUN=true in dry-run mode' do
      env['DRY_RUN'] = 'true'
      expect(wrapper).to receive(:run_rails_provisioner!)
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

    it 'passes only the pass-through variables through the child env' do
      captured_env = nil
      allow(wrapper).to receive(:system) do |*args|
        captured_env = args.first
        true
      end
      allow(wrapper).to receive(:run_rails_provisioner!).and_call_original

      wrapper.run

      expect(captured_env).to include(
        'CUTOVER_TENANT',
        'WHATSAPP_PHONE_NUMBER',
        'WHATSAPP_BUSINESS_PORTFOLIO_ID',
        'WHATSAPP_ACCESS_TOKEN',
        'WHATSAPP_APP_SECRET',
        'WHATSAPP_CUTOVER_RUNNING'
      )
      expect(captured_env).not_to include('HUBSPOT_ACCESS_TOKEN', 'HUBSPOT_CHANNEL_ACCOUNT_ID')
    end

    it 'does not write sensitive values to stdout or stderr on success' do
      stdout, stderr, error = capture_output { wrapper.run }
      expect(error).to be_nil
      combined = stdout + stderr

      sensitive_values.each do |value|
        expect(combined).not_to include(value)
      end
    end

    it 'does not write sensitive values to stdout, stderr, or raised messages on confirmation mismatch' do
      env['CUTOVER_CONFIRMATION'] = 'wrong'
      stdout, stderr, error = capture_output { wrapper.run }

      expect(error).to be_a(StandardError)
      combined = stdout + stderr + error.message
      sensitive_values.each do |value|
        expect(combined).not_to include(value)
      end
    end

    it 'does not write sensitive values to stdout, stderr, or raised messages on missing variables' do
      env.delete('WHATSAPP_ACCESS_TOKEN')
      stdout, stderr, error = capture_output { wrapper.run }

      expect(error).to be_a(StandardError)
      combined = stdout + stderr + error.message
      sensitive_values.each do |value|
        expect(combined).not_to include(value)
      end
    end

    it 'does not write sensitive values to stdout, stderr, or raised messages when HubSpot blocks cutover' do
      checker = instance_double(Myinvest::WhatsappCutover::HubspotChannelChecker, cutover_allowed?: false)
      allow(Myinvest::WhatsappCutover::HubspotChannelChecker).to receive(:new).and_return(checker)
      stdout, stderr, error = capture_output { wrapper.run }

      expect(error).to be_a(StandardError)
      combined = stdout + stderr + error.message
      sensitive_values.each do |value|
        expect(combined).not_to include(value)
      end
    end

    it 'does not write sensitive values to stdout, stderr, or raised messages when the Rails provisioner fails' do
      allow(wrapper).to receive(:run_rails_provisioner!).and_call_original
      allow(wrapper).to receive(:system).and_return(false)
      stdout, stderr, error = capture_output { wrapper.run }

      expect(error).to be_a(StandardError)
      combined = stdout + stderr + error.message
      sensitive_values.each do |value|
        expect(combined).not_to include(value)
      end
      expect(error.message).to eq('Rails provisioner failed')
    end
  end

  describe Myinvest::WhatsappCutover::Bootstrap::Runner do
    subject(:runner) { described_class.new(runner_env) }

    let(:tenant_account) { create(:account, name: 'Academy Alt', custom_attributes: { 'myinvest_tenant_key' => 'legacy_academy' }) }
    let(:runner_env) do
      {
        'CUTOVER_TENANT' => 'legacy_academy',
        'WHATSAPP_PHONE_NUMBER' => '+491234567890',
        'WHATSAPP_PHONE_NUMBER_ID' => '1234567890',
        'WHATSAPP_WABA_ID' => '9876543210',
        'WHATSAPP_BUSINESS_PORTFOLIO_ID' => '1122334455',
        'WHATSAPP_ACCESS_TOKEN' => 'super-secret-access-token',
        'WHATSAPP_APP_SECRET' => 'super-secret-app-secret'
      }
    end
    let(:frontend_url) { 'https://support.myinvest-pro.de' }
    let(:health_status) do
      {
        id: runner_env['WHATSAPP_PHONE_NUMBER_ID'],
        display_phone_number: runner_env['WHATSAPP_PHONE_NUMBER'],
        business_account_id: runner_env['WHATSAPP_WABA_ID'],
        business_portfolio_id: runner_env['WHATSAPP_BUSINESS_PORTFOLIO_ID'],
        status: 'CONNECTED',
        code_verification_status: 'VERIFIED',
        platform_type: 'CLOUD_API',
        quality_rating: 'GREEN',
        webhook_configuration: {
          'override_callback_uri' => "#{frontend_url}/webhooks/whatsapp/#{runner_env['WHATSAPP_PHONE_NUMBER']}"
        }
      }
    end

    around do |example|
      with_modified_env FRONTEND_URL: frontend_url do
        example.run
      end
    end

    before do
      tenant_account
      create(:account_user, account: tenant_account, user: create(:user), role: :administrator)
      create(:agent_bot, account: tenant_account, name: 'MyInvest Claude Support')
      allow_any_instance_of(Channel::Whatsapp).to receive(:sync_templates)
      allow_any_instance_of(Whatsapp::Providers::WhatsappCloudService)
        .to receive(:validate_provider_config?).and_return(true)
      allow_any_instance_of(Whatsapp::WebhookSetupService).to receive(:perform).and_return(true)
      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(health_status)
    end

    def capture_runner_output
      old_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end

    it 'prints a generic message on success without identifiers' do
      output = capture_runner_output { runner.run }

      expect(output).to include('[WHATSAPP_CUTOVER] completed')
      expect(output).not_to include(runner_env['WHATSAPP_PHONE_NUMBER'])
      expect(output).not_to include(runner_env['WHATSAPP_PHONE_NUMBER_ID'])
      expect(output).not_to include(runner_env['WHATSAPP_WABA_ID'])
      expect(output).not_to include(runner_env['WHATSAPP_BUSINESS_PORTFOLIO_ID'])
      expect(output).not_to include(runner_env['WHATSAPP_ACCESS_TOKEN'])
      expect(output).not_to include(runner_env['WHATSAPP_APP_SECRET'])
      expect(output).not_to include(tenant_account.id.to_s)
    end

    it 'prints a generic message in dry-run mode without identifiers' do
      runner_env['DRY_RUN'] = 'true'
      output = capture_runner_output { runner.run }

      expect(output).to include('[WHATSAPP_CUTOVER] dry run completed')
      expect(output).not_to include(runner_env['WHATSAPP_PHONE_NUMBER'])
      expect(output).not_to include(tenant_account.id.to_s)
    end

    it 'raises generic errors without identifiers when the tenant is missing' do
      runner_env['CUTOVER_TENANT'] = 'unknown_tenant'

      expect { runner.run }.to raise_error do |error|
        expect(error.message).to eq('Tenant not found')
        expect(error.message).not_to include('unknown_tenant')
      end
    end

    it 'raises generic errors without identifiers when variables are missing' do
      token = runner_env.delete('WHATSAPP_ACCESS_TOKEN')

      expect { runner.run }.to raise_error do |error|
        expect(error.message).to include('Missing cutover variables')
        expect(error.message).not_to include(runner_env['WHATSAPP_PHONE_NUMBER'])
        expect(error.message).not_to include(token)
      end
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

    it 'raises a generic error on HubSpot API errors' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 401, body: '{}')

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot API error/)
    end

    it 'does not include the HTTP response body in API error messages' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 401, body: { 'secret' => 'leaked-token' }.to_json)

      expect { checker.cutover_allowed? }.to raise_error do |error|
        expect(error.message).not_to include('leaked-token')
      end
    end

    it 'rejects a page without a results array' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: { 'results' => 'not-an-array' }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end

    it 'rejects a result that is not a hash' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: { 'results' => ['account-1'] }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end

    it 'rejects string boolean flags' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'account-1', 'active' => 'false', 'authorized' => 'false' }]
        }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end

    it 'rejects a repeated pagination cursor' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [],
          'paging' => { 'next' => { 'after' => 'stuck' } }
        }.to_json)
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts\?.*after=stuck.*})
        .to_return(status: 200, body: {
          'results' => [],
          'paging' => { 'next' => { 'after' => 'stuck' } }
        }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot pagination error/)
    end

    it 'rejects a result missing an id' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [{ 'active' => false, 'authorized' => false }]
        }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end

    it 'rejects a result missing active or authorized flags' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: {
          'results' => [{ 'id' => 'account-1' }]
        }.to_json)

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end

    it 'raises a generic error on invalid JSON' do
      stub_request(:get, %r{api\.hubapi\.com/conversations/v3/conversations/channel-accounts.*})
        .to_return(status: 200, body: 'not-json')

      expect { checker.cutover_allowed? }.to raise_error(/HubSpot response invalid/)
    end
  end
end
