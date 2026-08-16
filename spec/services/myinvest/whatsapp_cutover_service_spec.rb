require 'rails_helper'
require_relative '../../../deployment/myinvest/bootstrap/lib/whatsapp_cutover'

describe Myinvest::WhatsappCutover::Service do
  subject(:service) do
    described_class.new(
      account: account,
      phone_number: phone_number,
      phone_number_id: phone_number_id,
      waba_id: waba_id,
      business_portfolio_id: business_portfolio_id,
      access_token: access_token,
      app_secret: app_secret
    )
  end

  let(:account) { create(:account, name: 'Academy Alt', custom_attributes: { 'myinvest_tenant_key' => 'legacy_academy' }) }
  let(:phone_number) { '+491234567890' }
  let(:phone_number_id) { '1234567890' }
  let(:waba_id) { '9876543210' }
  let(:business_portfolio_id) { 'portfolio-1' }
  let(:access_token) { 'super-secret-access-token' }
  let(:app_secret) { 'super-secret-app-secret' }

  let(:health_status) do
    {
      id: phone_number_id,
      display_phone_number: phone_number,
      business_account_id: waba_id,
      business_portfolio_id: business_portfolio_id,
      status: 'CONNECTED',
      code_verification_status: 'VERIFIED',
      platform_type: 'CLOUD_API',
      quality_rating: 'GREEN',
      expected_webhook_url: "https://support.myinvest-pro.de/webhooks/whatsapp/#{phone_number}",
      webhook_configuration: {
        'override_callback_uri' => "https://support.myinvest-pro.de/webhooks/whatsapp/#{phone_number}"
      }
    }
  end

  before do
    allow_any_instance_of(Channel::Whatsapp).to receive(:sync_templates)
    allow_any_instance_of(Whatsapp::Providers::WhatsappCloudService)
      .to receive(:validate_provider_config?).and_return(true)
    allow_any_instance_of(Whatsapp::WebhookSetupService).to receive(:perform).and_return(true)
    allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(health_status)
  end

  def build_service(overrides = {})
    described_class.new(
      account: account,
      phone_number: phone_number,
      phone_number_id: phone_number_id,
      waba_id: waba_id,
      business_portfolio_id: business_portfolio_id,
      access_token: access_token,
      app_secret: app_secret, **overrides
    )
  end

  def create_existing_channel(config)
    channel = create(
      :channel_whatsapp,
      account: account,
      phone_number: phone_number,
      provider: 'default',
      sync_templates: false,
      validate_provider_config: false
    )
    channel.update!(provider: 'whatsapp_cloud', provider_config: config)
    channel
  end

  describe '#initialize' do
    it 'requires account' do
      expect { build_service(account: nil) }
        .to raise_error(ArgumentError, 'Account is required')
    end

    it 'requires phone number' do
      expect { build_service(phone_number: '') }
        .to raise_error(ArgumentError, 'Phone number is required')
    end

    it 'requires phone number id' do
      expect { build_service(phone_number_id: '') }
        .to raise_error(ArgumentError, 'Phone number ID is required')
    end

    it 'requires waba id' do
      expect { build_service(waba_id: '') }
        .to raise_error(ArgumentError, 'WABA ID is required')
    end

    it 'requires access token' do
      expect { build_service(access_token: '') }
        .to raise_error(ArgumentError, 'Access token is required')
    end

    it 'requires app secret' do
      expect { build_service(app_secret: '') }
        .to raise_error(ArgumentError, 'App secret is required')
    end

    it 'requires business portfolio id' do
      expect { build_service(business_portfolio_id: '') }
        .to raise_error(ArgumentError, 'Business portfolio ID is required')
    end
  end

  describe '#perform' do
    it 'creates a whatsapp_cloud inbox with app_secret in provider_config' do
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }
        .to change(Channel::Whatsapp, :count).by(1).and change(Inbox, :count).by(1)

      channel = Channel::Whatsapp.last
      expect(channel.account).to eq(account)
      expect(channel.phone_number).to eq(phone_number)
      expect(channel.provider).to eq('whatsapp_cloud')
      expect(channel.provider_config['api_key']).to eq(access_token)
      expect(channel.provider_config['phone_number_id']).to eq(phone_number_id)
      expect(channel.provider_config['business_account_id']).to eq(waba_id)
      expect(channel.provider_config['app_secret']).to eq(app_secret)
      expect(channel.provider_config['source']).to eq('embedded_signup')
    end

    it 'reuses an existing matching channel on rerun and refreshes the provider config' do
      existing = create_existing_channel(
        'api_key' => 'old-token',
        'phone_number_id' => phone_number_id,
        'business_account_id' => waba_id,
        'app_secret' => 'old-secret',
        'source' => 'embedded_signup',
        'webhook_verify_token' => 'existing-token'
      )
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }.not_to change(Channel::Whatsapp, :count)
      expect(service.perform).to eq(existing)

      existing.reload
      expect(existing.provider_config['api_key']).to eq(access_token)
      expect(existing.provider_config['app_secret']).to eq(app_secret)
      expect(existing.provider_config['webhook_verify_token']).to eq('existing-token')
    end

    it 'fails closed on cross-account phone conflicts' do
      other_account = create(:account)
      create(
        :channel_whatsapp,
        account: other_account,
        phone_number: phone_number,
        provider: 'default',
        sync_templates: false,
        validate_provider_config: false
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::ConflictError, /cross-account cutover rejected/)
    end

    it 'fails closed on WABA mismatch' do
      create_existing_channel(
        'api_key' => access_token,
        'phone_number_id' => phone_number_id,
        'business_account_id' => 'other-waba',
        'source' => 'embedded_signup'
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::ConflictError, /requested WABA .* conflicts/)
    end

    it 'fails closed on phone number id mismatch' do
      create_existing_channel(
        'api_key' => access_token,
        'phone_number_id' => 'other-id',
        'business_account_id' => waba_id,
        'source' => 'embedded_signup'
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::ConflictError, /phone_number_id .* conflicts/)
    end

    it 'propagates webhook setup failures' do
      allow_any_instance_of(Whatsapp::WebhookSetupService)
        .to receive(:perform).and_raise('Meta webhook error')

      expect { service.perform }.to raise_error(RuntimeError, 'Meta webhook error')
    end

    it 'verifies health before attaching agent bot' do
      admin = create(:user)
      create(:account_user, account: account, user: admin, role: :administrator)
      agent_bot = create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }.to change(AgentBotInbox, :count).by(1)

      channel = Channel::Whatsapp.last
      expect(AgentBotInbox.find_by!(inbox: channel.inbox).agent_bot).to eq(agent_bot)
    end

    it 'fails closed when the agent bot is missing after health passes' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::ConfigurationError, /Agent bot/)
    end

    it 'fails closed when no administrator exists after health passes' do
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::ConfigurationError, /administrator/)
    end

    it 'does not attach agent bot when health check fails' do
      allow_any_instance_of(Whatsapp::HealthService)
        .to receive(:fetch_health_status).and_raise('Meta health error')
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, 'Health check failed')
      expect(AgentBotInbox.count).to eq(0)
    end

    it 'assigns an existing administrator to the inbox' do
      admin = create(:user)
      create(:account_user, account: account, user: admin, role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      expect { service.perform }.to change(InboxMember, :count).by(1)

      channel = Channel::Whatsapp.last
      expect(channel.inbox.members).to include(admin)
    end

    it 'rejects a business portfolio ID mismatch in health' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(business_portfolio_id: 'other-portfolio')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /business portfolio mismatch/)
    end

    it 'requires a business portfolio ID in health' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(business_portfolio_id: '')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /business portfolio mismatch/)
    end

    it 'requires CONNECTED status' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(status: 'DISCONNECTED')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /status mismatch/)
    end

    it 'requires VERIFIED code verification status' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(code_verification_status: 'PENDING')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /code verification mismatch/)
    end

    it 'requires CLOUD_API platform type' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(platform_type: 'ON_PREM')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /platform type mismatch/)
    end

    it 'rejects risky quality ratings' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')

      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(quality_rating: 'RED')
      )

      expect { service.perform }
        .to raise_error(Myinvest::WhatsappCutover::HealthError, /quality rating mismatch/)
    end

    it 'does not leak secrets in raised messages' do
      other_account = create(:account)
      create(
        :channel_whatsapp,
        account: other_account,
        phone_number: phone_number,
        provider: 'default',
        sync_templates: false,
        validate_provider_config: false
      )

      expect { service.perform }.to raise_error do |error|
        expect(error.message).not_to include(access_token)
        expect(error.message).not_to include(app_secret)
        expect(error.message).to include(phone_number.gsub(/(?<=.{4}).(?=.{2})/, '*'))
      end
    end

    it 'does not log secrets' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')
      logged = []
      allow(Rails.logger).to receive(:info) { |message| logged << message.to_s }

      service.perform

      expect(logged.join("\n")).not_to include(access_token)
      expect(logged.join("\n")).not_to include(app_secret)
    end

    it 'does not leak secrets from health mismatch errors' do
      create(:user)
      create(:account_user, account: account, user: create(:user), role: :administrator)
      create(:agent_bot, account: account, name: 'MyInvest Claude Support')
      allow_any_instance_of(Whatsapp::HealthService).to receive(:fetch_health_status).and_return(
        health_status.merge(
          webhook_configuration: {
            'override_callback_uri' => "https://evil.example/#{access_token}/#{app_secret}"
          }
        )
      )

      expect { service.perform }.to raise_error do |error|
        expect(error).to be_a(Myinvest::WhatsappCutover::HealthError)
        expect(error.message).not_to include(access_token)
        expect(error.message).not_to include(app_secret)
      end
    end
  end
end
