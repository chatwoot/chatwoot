# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Whatsapp do
  describe '#serializable_hash' do
    it 'does not expose the business management token' do
      channel = build(:channel_whatsapp, business_management_token: 'business-token')

      expect(channel.serializable_hash).not_to have_key('business_management_token')
    end
  end

  describe '#template_access_token' do
    let(:channel) do
      build(
        :channel_whatsapp,
        provider: 'whatsapp_cloud',
        provider_config: { 'api_key' => 'api-key', 'source' => source },
        business_management_token: business_management_token
      )
    end
    let(:source) { 'embedded_signup' }

    context 'when running on Chatwoot Cloud' do
      before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

      context 'with a business management token' do
        let(:business_management_token) { 'business-token' }

        it 'uses the business management token' do
          expect(channel.template_access_token).to eq('business-token')
        end
      end

      context 'without a business management token' do
        let(:business_management_token) { nil }

        it 'uses the provider API key' do
          expect(channel.template_access_token).to eq('api-key')
        end
      end

      context 'with a manually configured inbox' do
        let(:business_management_token) { 'business-token' }
        let(:source) { nil }

        it 'ignores the business management token' do
          expect(channel.template_access_token).to eq('api-key')
        end
      end
    end

    context 'when running outside Chatwoot Cloud' do
      before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false) }

      let(:business_management_token) { 'business-token' }

      it 'ignores the business management token' do
        expect(channel.template_access_token).to eq('api-key')
      end
    end
  end

  # The incident behind these: a coexistence number whose WABA sits in the customer's own
  # Business Manager answers the phone-level override with `(#200) Permissions error`, because
  # the integrator's system user cannot manage a WABA in another portfolio. Under a shared
  # rescue that refusal marked the channel for reauthorization, and `Webhooks::WhatsappEventsJob`
  # then discarded every inbound webhook for it: the number was dead for hours while Meta kept
  # delivering, nine webhooks in and no conversations out.
  describe '#setup_webhooks' do
    let(:waba_id) { 'waba_568' }
    let(:phone_number_id) { 'phone_568' }
    # Written after create, not through the factory: its `whatsapp_cloud` branch merges its own
    # ids over whatever the caller passed, so a phone number id given here would be silently
    # replaced by the WABA's and the two calls would be indistinguishable in the stubs.
    let(:channel) do
      create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false).tap do |created|
        created.provider_config = { 'api_key' => 'test_key', 'phone_number_id' => phone_number_id,
                                    'business_account_id' => waba_id, 'source' => 'embedded_signup',
                                    'webhook_verify_token' => 'verify_token' }
        created.save!(validate: false)
      end
    end

    before do
      stub_request(:get, %r{graph\.facebook\.com/.*/#{phone_number_id}})
        .to_return(status: 200, body: { code_verification_status: 'VERIFIED', platform_type: 'CLOUD_API' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps})
        .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      # Read while the reauthorization notice is built, so only the failing branch reaches it.
      stub_request(:get, %r{graph\.facebook\.com/.*/#{waba_id}\?})
        .to_return(status: 200, body: { id: waba_id, name: 'WABA' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when only the phone-level callback override fails' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{phone_number_id}\z})
          .to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'keeps the channel authorized, because the WABA subscription is what makes Meta deliver' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end
    end

    # The same refusal reaches this code as a 403 carrying Meta's code 200, as a plain 500, and
    # as a connection that closes with nothing to read. A fix that keys on the status or on the
    # message covers the first and leaves the other two marking the channel.
    context 'when the override fails with no response at all' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{phone_number_id}\z}).to_raise(Errno::ECONNRESET)
      end

      it 'keeps the channel authorized' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end
    end

    context 'when Meta answers that the credentials are the problem' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps})
          .to_return(status: 401,
                     body: { error: { message: 'Error validating access token', type: 'OAuthException', code: 190 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'marks the channel for reauthorization' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(true)
      end

      it 'tells the operator, because a revoked token only gets fixed by hand' do
        admin_mailer = double
        mailer_double = double
        allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        allow(admin_mailer).to receive(:whatsapp_disconnect).and_return(mailer_double)
        allow(mailer_double).to receive(:deliver_later)

        channel.setup_webhooks

        expect(admin_mailer).to have_received(:whatsapp_disconnect).with(channel.inbox)
      end
    end

    # A ceiling that stops the wait says nothing about the credentials, and `prompt_reauthorization!`
    # is not a log line: it writes the marker, runs the handler that emails the operator, invalidates
    # the inbox cache and fires the event, and `Webhooks::WhatsappEventsJob` discards every inbound
    # webhook while the marker stands. So the alarm has to come from an answer, never from silence.
    context 'when the WABA subscription never answers' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps}).to_timeout
      end

      it 'leaves the channel authorized' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end

      it 'does not email the operator about a disconnection that was never established' do
        expect(AdministratorNotifications::ChannelNotificationsMailer).not_to receive(:with)

        channel.setup_webhooks
      end
    end

    context 'when the WABA subscription answers with a server error' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps})
          .to_return(status: 500, body: { error: { message: 'Internal error', code: 1 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'leaves the channel authorized, because a bad minute at Meta is not a bad credential' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end
    end

    # The refusal a coexistence number gets every time its WABA sits in the customer's own Business
    # Manager. The optional half already survives it; the required half used to mark the channel.
    context 'when Meta refuses the WABA subscription with a permissions error' do
      before do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps})
          .to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'leaves the channel authorized' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end
    end

    # `cause` is only set by raising inside a rescue, which is what the setup service does when it
    # re-raises with a prefix. Built here rather than provoked, because provoking it would mean
    # stubbing the Graph client instance the service builds for itself.
    def wrapped(inner)
      raise inner
    rescue StandardError => e
      begin
        raise "Webhook setup failed: #{e.message}"
      rescue StandardError => wrapper
        wrapper
      end
    end

    context 'when something inside the Graph call path raises ArgumentError' do
      it 'leaves the channel authorized, because that one is not about a credential' do
        allow(channel).to receive(:perform_webhook_setup).and_raise(wrapped(ArgumentError.new('bad callback url')))

        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(false)
      end
    end

    # The line is the only place a diagnosis starts from, and the two ways in are not the same fact:
    # one of them never reached Meta at all. Saying Meta refused there would be the same trade this
    # change exists to stop, one layer down.
    describe 'the line that says why reauthorization was asked for' do
      it 'says Meta answered, when Meta answered' do
        stub_request(:post, %r{graph\.facebook\.com/.*/#{waba_id}/subscribed_apps})
          .to_return(status: 401, body: { error: { message: 'Error validating access token', code: 190 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        allow(Rails.logger).to receive(:error)

        channel.setup_webhooks

        expect(Rails.logger).to have_received(:error)
          .with("[WHATSAPP] Asking for reauthorization on channel #{channel.id}: " \
                'Meta answered that the credentials are the problem')
      end

      it 'says the setup could not run, when nothing ever left' do
        channel.provider_config = channel.provider_config.merge('api_key' => '')
        channel.save!(validate: false)
        allow(Rails.logger).to receive(:error)

        channel.setup_webhooks

        expect(Rails.logger).to have_received(:error)
          .with("[WHATSAPP] Asking for reauthorization on channel #{channel.id}: " \
                'the setup could not run without a credential')
      end
    end

    context 'when the setup cannot run because there is no access token' do
      before do
        channel.provider_config = channel.provider_config.merge('api_key' => '')
        channel.save!(validate: false)
      end

      it 'marks the channel for reauthorization, because a missing credential is not silence' do
        channel.setup_webhooks

        expect(channel.reauthorization_required?).to be(true)
      end
    end
  end

  describe 'concerns' do
    let(:channel) { create(:channel_whatsapp) }

    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
    end

    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for whatsapp' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:whatsapp_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end

  describe 'validate_provider_config' do
    let(:channel) do
      build(:channel_whatsapp, provider: 'whatsapp_cloud', account: create(:account),
                               provider_config: { 'api_key' => 'test_key', 'phone_number_id' => 'random_id', 'app_secret' => 'test_secret' })
    end

    it 'validates false when provider config is wrong' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key').to_return(status: 401)
      expect(channel.save).to be(false)
    end

    it 'validates true when provider config is right' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key')
        .to_return(status: 200,
                   body: { data: [{
                     id: '123456789', name: 'test_template'
                   }] }.to_json)
      stub_request(:get, 'https://graph.facebook.com/v14.0//phone_numbers?fields=id&limit=100&access_token=test_key')
        .to_return(status: 200, body: { data: [{ id: 'random_id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{\Ahttps://graph.facebook.com/v[\d.]+/me\?}).to_return(status: 200, body: { id: '1' }.to_json)
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(channel.save).to be(true)
    end

    it 'validates false when phone number id is wrong' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key')
        .to_return(status: 200, body: { data: [] }.to_json)
      stub_request(:get, 'https://graph.facebook.com/v14.0//phone_numbers?fields=id&limit=100&access_token=test_key')
        .to_return(status: 200, body: { data: [{ id: 'another_phone_id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(channel.save).to be(false)
    end
  end

  describe 'app secret requirement' do
    let(:account) { create(:account) }
    let(:manual_config) { { 'api_key' => 'test_key', 'phone_number_id' => '123456789', 'source' => 'manual_setup_v2' } }

    def build_manual_channel(provider_config)
      build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', provider_config: provider_config).tap do |channel|
        allow(channel).to receive(:validate_provider_config)
        allow(channel).to receive(:sync_templates)
      end
    end

    it 'is required to create a manual whatsapp cloud channel' do
      channel = build_manual_channel(manual_config)

      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('App secret is required')
    end

    it 'creates a manual whatsapp cloud channel with an app secret' do
      expect(build_manual_channel(manual_config.merge('app_secret' => 'secret'))).to be_valid
    end

    it 'is not required for embedded signup channels' do
      expect(build_manual_channel(manual_config.merge('source' => 'embedded_signup'))).to be_valid
    end

    context 'with an existing manual channel without an app secret' do
      let(:channel) do
        build_manual_channel(manual_config).tap { |channel| channel.save!(validate: false) }
      end

      it 'is pending app secret setup' do
        expect(channel.app_secret_pending?).to be(true)
      end

      it 'still allows updates without an app secret' do
        channel.provider_config = channel.provider_config.merge('api_key' => 'new_key')

        expect(channel).to be_valid
      end

      it 'is no longer pending once an app secret is added' do
        channel.update!(provider_config: channel.provider_config.merge('app_secret' => 'secret'))

        expect(channel.app_secret_pending?).to be(false)
      end
    end

    # The fork keeps the stored secret over an update that leaves it out (keep_app_secret), so a
    # configured secret cannot be removed by an update at all.
    it 'cannot be removed once configured' do
      channel = build_manual_channel(manual_config.merge('app_secret' => 'secret'))
      channel.save!
      channel.provider_config = channel.provider_config.except('app_secret')

      expect(channel).to be_valid
      expect(channel.provider_config['app_secret']).to eq('secret')
    end

    it 'is required when a 360dialog channel switches to whatsapp cloud' do
      channel = build(:channel_whatsapp, account: account, provider: 'default').tap do |dialog_channel|
        allow(dialog_channel).to receive(:validate_provider_config)
        allow(dialog_channel).to receive(:sync_templates)
      end
      channel.save!
      channel.assign_attributes(provider: 'whatsapp_cloud', provider_config: manual_config)

      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('App secret is required')
    end

    it 'is required when an embedded signup channel moves to manual setup' do
      channel = build_manual_channel(manual_config.merge('source' => 'embedded_signup'))
      channel.save!
      channel.provider_config = channel.provider_config.merge('source' => 'manual_setup_v2')

      expect(channel).not_to be_valid
    end
  end

  describe 'webhook_verify_token' do
    before do
      # Stub webhook setup to prevent HTTP calls during channel creation
      setup_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
      allow(setup_service).to receive(:perform)
    end

    it 'generates webhook_verify_token if not present' do
      channel = create(:channel_whatsapp,
                       provider_config: {
                         'webhook_verify_token' => nil,
                         'api_key' => 'test_key',
                         'business_account_id' => '123456789'
                       },
                       provider: 'whatsapp_cloud',
                       account: create(:account),
                       validate_provider_config: false,
                       sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).not_to be_nil
    end

    it 'does not generate webhook_verify_token if present' do
      channel = create(:channel_whatsapp,
                       provider: 'whatsapp_cloud',
                       provider_config: {
                         'webhook_verify_token' => '123',
                         'api_key' => 'test_key',
                         'business_account_id' => '123456789'
                       },
                       account: create(:account),
                       validate_provider_config: false,
                       sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).to eq '123'
    end

    context 'when an update writes provider_config without the token' do
      %w[baileys whatsapp_cloud zapi].each do |provider|
        it "keeps the stored token on #{provider}" do
          channel = create(:channel_whatsapp, provider: provider,
                                              provider_config: { 'webhook_verify_token' => 'stored-token', 'api_key' => 'test_key' },
                                              validate_provider_config: false, sync_templates: false)

          channel.update!(provider_config: { 'api_key' => 'rotated_key', 'app_secret' => 'test_app_secret' })

          expect(channel.reload.provider_config).to include('webhook_verify_token' => 'stored-token', 'api_key' => 'rotated_key')
        end
      end
    end

    it 'keeps the stored token when an update hands in another one' do
      channel = create(:channel_whatsapp, provider: 'baileys', provider_config: { 'webhook_verify_token' => 'stored-token' },
                                          validate_provider_config: false, sync_templates: false)

      channel.update!(provider_config: { 'webhook_verify_token' => 'chosen-by-caller' })

      expect(channel.reload.provider_config['webhook_verify_token']).to eq 'stored-token'
    end

    # Z-API's token is born with the URL that carries it; one minted here would close the old
    # URL before Z-API had been told about the new one.
    it 'does not mint a token for zapi' do
      channel = create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false)

      channel.update!(provider_config: channel.provider_config.merge('instance_id' => 'other'))

      expect(channel.reload.provider_config).not_to have_key('webhook_verify_token')
    end

    it 'keeps the confirmation of the zapi URL across an update that leaves it out' do
      channel = create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false)
      channel.provider_config = channel.provider_config.merge('instance_id' => 'i1', 'webhook_verify_token' => 't',
                                                              'webhook_url_confirmed_for' => 'i1')
      channel.save!(validate: false)

      channel.update!(provider_config: { 'instance_id' => 'i1' })

      expect(channel.reload.provider_config).to include('webhook_verify_token' => 't', 'webhook_url_confirmed_for' => 'i1')
    end

    # The token a rotation replaced is the inbox's own: an update can neither close it early nor
    # name one of its own choosing.
    it 'keeps the replaced zapi token as stored, whatever an update sends' do
      channel = create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false)
      channel.provider_config = channel.provider_config.merge('webhook_verify_token' => 't', 'previous_webhook_verify_token' => 'old')
      channel.save!(validate: false)

      channel.update!(provider_config: { 'instance_id' => 'i1' })
      expect(channel.reload.provider_config['previous_webhook_verify_token']).to eq('old')

      channel.update_column(:provider_config, channel.provider_config.except('previous_webhook_verify_token')) # rubocop:disable Rails/SkipsModelValidations
      channel.update!(provider_config: channel.reload.provider_config.merge('previous_webhook_verify_token' => 'chosen'))
      expect(channel.reload.provider_config).not_to have_key('previous_webhook_verify_token')
    end

    # An inbox update loaded before Z-API's token was reserved must not write the config back without it.
    it 'keeps a zapi token reserved after the record being saved was loaded' do
      channel = create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false)
      described_class.find(channel.id).tap do |other|
        other.provider_config = other.provider_config.merge('webhook_verify_token' => 'reserved')
        other.save!(validate: false)
      end

      channel.update!(provider_config: channel.provider_config.merge('client_token' => 'edited'))

      expect(channel.reload.provider_config).to include('webhook_verify_token' => 'reserved', 'client_token' => 'edited')
    end

    it 'does not carry the token across a provider change' do
      channel = create(:channel_whatsapp, provider: 'baileys', provider_config: { 'webhook_verify_token' => 'stored-token' },
                                          validate_provider_config: false, sync_templates: false)

      channel.assign_attributes(provider: 'whatsapp_cloud', provider_config: { 'api_key' => 'test_key' })
      channel.valid?

      expect(channel.provider_config['webhook_verify_token']).to be_present.and(satisfy { |token| token != 'stored-token' })
    end
  end

  describe 'app secret' do
    let(:account) { create(:account) }

    it 'is asked for when a manual cloud inbox is created' do
      channel = build(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                         provider_config: { 'api_key' => 'k', 'phone_number_id' => '1', 'business_account_id' => '2' })
      channel.define_singleton_method(:validate_provider_config) { nil }

      expect(channel.valid?).to be(false)
      expect(channel.errors[:provider_config]).to include('App secret is required')
    end

    it 'is not asked of an embedded signup inbox, which runs on the installation app' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)

      expect(channel.provider_config).not_to have_key('app_secret')
      expect(channel).to be_valid
    end

    it 'is asked for when an inbox moves off embedded signup' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
      channel.define_singleton_method(:validate_provider_config) { nil }

      channel.provider_config = channel.provider_config.merge('source' => 'manual')

      expect(channel.valid?).to be(false)
      expect(channel.errors[:provider_config]).to include('App secret is required')
    end

    # Left out by a wholesale replace, it would turn verified webhooks back into unsigned ones.
    it 'is kept when an update leaves it out' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, provider_config: { 'source' => 'manual_setup_v2' },
                                          validate_provider_config: false, sync_templates: false)
      expect(channel.provider_config['app_secret']).to be_present

      channel.update!(provider_config: channel.provider_config.except('app_secret').merge('api_key' => 'rotated'))

      expect(channel.reload.provider_config).to include('app_secret' => 'test_app_secret', 'api_key' => 'rotated')
    end

    it 'is kept on a 360dialog inbox too' do
      channel = create(:channel_whatsapp, provider: 'default', account: account, validate_provider_config: false, sync_templates: false)
      channel.update_column(:provider_config, channel.provider_config.merge('app_secret' => 'dialog_secret')) # rubocop:disable Rails/SkipsModelValidations
      channel.reload.define_singleton_method(:validate_provider_config) { nil }

      channel.update!(provider_config: { 'api_key' => 'rotated' })

      expect(channel.reload.provider_config).to include('app_secret' => 'dialog_secret', 'api_key' => 'rotated')
    end

    # Reauthorized through embedded signup, the inbox is verified with the installation's secret,
    # and the manual app's one would be checked against a token it did not issue.
    it 'is dropped when a manual inbox moves to embedded signup' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, provider_config: { 'source' => 'manual_setup_v2' },
                                          validate_provider_config: false, sync_templates: false)

      channel.update!(provider_config: channel.provider_config.merge('source' => 'embedded_signup', 'api_key' => 'embedded_token'))

      expect(channel.reload.provider_config).not_to have_key('app_secret')
    end

    # Inboxes from before the secret was asked for keep working until their operator adds one.
    it 'is not asked of a manual inbox that already exists' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, provider_config: { 'source' => 'manual_setup_v2' },
                                          validate_provider_config: false, sync_templates: false)
      channel.update_column(:provider_config, channel.provider_config.except('app_secret')) # rubocop:disable Rails/SkipsModelValidations
      stub_request(:get, /graph\.facebook\.com/).to_return(status: 200, body: { data: [{ id: '123456789' }] }.to_json,
                                                           headers: { 'Content-Type' => 'application/json' })

      channel.reload.provider_config = channel.provider_config.merge('api_key' => 'rotated')

      expect(channel.valid?).to be(true), channel.errors.full_messages.inspect
    end
  end

  describe 'webhook_token' do
    let(:webhook_url) { 'https://waba.360dialog.io/v1/configs/webhook' }
    let(:channel) do
      existing = create(:channel_whatsapp, provider: 'default', sync_templates: false, validate_provider_config: false)
      existing.update_column(:provider_config, existing.provider_config.except('webhook_token')) # rubocop:disable Rails/SkipsModelValidations
      described_class.find(existing.id)
    end

    it 'registers the webhook url with a new webhook token on save' do
      stub_request(:post, webhook_url)

      channel.update!(message_templates: [])

      token = channel.reload.provider_config['webhook_token']
      expect(token).to be_present
      expect(a_request(:post, webhook_url).with { |req| JSON.parse(req.body)['url'].end_with?("?webhook_token=#{token}") }).to have_been_made
    end

    it 'registers the same webhook token from overlapping saves' do
      registered_urls = []
      stub_request(:post, webhook_url).with { |req| registered_urls << JSON.parse(req.body)['url'] }
      stale_channel = described_class.find(channel.id)

      channel.update!(message_templates: [])
      stale_channel.update!(message_templates: [])

      token = channel.reload.provider_config['webhook_token']
      expect(registered_urls.map { |url| url.split('?webhook_token=').last }).to eq([token, token])
    end

    it 'does not store the webhook token when the webhook url is not accepted' do
      stub_request(:post, webhook_url).to_return(status: 401)

      expect(channel.update(message_templates: [])).to be(false)
      expect(channel.reload.provider_config['webhook_token']).to be_nil
    end

    it 'does not register the webhook url when the channel is invalid' do
      stub_request(:post, webhook_url)
      duplicate = described_class.new(account: channel.account, provider: 'default', phone_number: channel.phone_number,
                                      provider_config: { 'api_key' => 'test_key' })

      expect(duplicate.save).to be(false)
      expect(a_request(:post, webhook_url)).not_to have_been_made
    end

    it 'keeps an existing webhook token' do
      stub_request(:post, webhook_url)
      channel.update!(provider_config: channel.provider_config.merge('webhook_token' => 'existing-token'))

      channel.update!(message_templates: [])

      expect(channel.reload.provider_config['webhook_token']).to eq('existing-token')
    end
  end

  describe 'webhook setup after creation' do
    let(:account) { create(:account) }
    let(:webhook_service) { instance_double(Whatsapp::WebhookSetupService) }

    before do
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)
    end

    context 'when channel is created through embedded signup' do
      it 'does not raise error if webhook setup fails' do
        allow(webhook_service).to receive(:perform).and_raise(StandardError, 'Webhook error')

        expect do
          create(:channel_whatsapp,
                 account: account,
                 provider: 'whatsapp_cloud',
                 provider_config: {
                   'source' => 'embedded_signup',
                   'business_account_id' => 'test_waba_id',
                   'api_key' => 'test_access_token'
                 },
                 validate_provider_config: false,
                 sync_templates: false)
        end.not_to raise_error
      end
    end

    context 'when channel is created through manual setup' do
      it 'setups webhooks via after_commit callback' do
        expect(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
        expect(webhook_service).to receive(:perform)

        # Explicitly set source to nil to test manual setup behavior (not embedded_signup)
        create(:channel_whatsapp,
               account: account,
               provider: 'whatsapp_cloud',
               provider_config: {
                 'business_account_id' => 'test_waba_id',
                 'api_key' => 'test_access_token',
                 'app_secret' => 'test_app_secret',
                 'source' => nil
               },
               validate_provider_config: false,
               sync_templates: false)
      end
    end

    context 'when channel is created with different provider' do
      it 'does not setup webhooks for 360dialog provider' do
        expect(Whatsapp::WebhookSetupService).not_to receive(:new)

        create(:channel_whatsapp,
               account: account,
               provider: 'default',
               provider_config: {
                 'source' => 'embedded_signup',
                 'api_key' => 'test_360dialog_key'
               },
               validate_provider_config: false,
               sync_templates: false)
      end
    end
  end

  describe '#teardown_webhooks' do
    let(:account) { create(:account) }

    context 'when channel is whatsapp_cloud with embedded_signup' do
      it 'calls WebhookTeardownService on destroy' do
        # Mock the setup service to prevent HTTP calls during creation
        setup_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
        allow(setup_service).to receive(:perform)

        channel = create(:channel_whatsapp,
                         account: account,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'source' => 'embedded_signup',
                           'business_account_id' => 'test_waba_id',
                           'api_key' => 'test_access_token',
                           'phone_number_id' => '123456789'
                         },
                         validate_provider_config: false,
                         sync_templates: false)

        teardown_service = instance_double(Whatsapp::WebhookTeardownService)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(channel).and_return(teardown_service)
        allow(teardown_service).to receive(:perform)

        channel.destroy!

        expect(Whatsapp::WebhookTeardownService).to have_received(:new).with(channel)
        expect(teardown_service).to have_received(:perform)
      end
    end

    context 'when channel is not embedded_signup' do
      it 'calls WebhookTeardownService on destroy' do
        # Mock the setup service to prevent HTTP calls during creation
        setup_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
        allow(setup_service).to receive(:perform)

        channel = create(:channel_whatsapp,
                         account: account,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'business_account_id' => 'test_waba_id',
                           'api_key' => 'test_access_token'
                         },
                         validate_provider_config: false,
                         sync_templates: false)

        teardown_service = instance_double(Whatsapp::WebhookTeardownService)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(channel).and_return(teardown_service)
        allow(teardown_service).to receive(:perform)

        channel.destroy!

        expect(teardown_service).to have_received(:perform)
      end
    end
  end

  describe '#toggle_typing_status' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }

    it 'calls provider service method' do
      message = create(:message, conversation: conversation)
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, toggle_typing_status: nil)
      allow(provider_double).to receive(:toggle_typing_status)
        .with(Events::Types::CONVERSATION_TYPING_ON, recipient_id: conversation.contact.identifier, last_message: message)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation)

      expect(provider_double).to have_received(:toggle_typing_status)
    end

    it 'does not call method if provider service does not implement it' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect do
        channel.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation)
      end.not_to raise_error
    end
  end

  describe '#update_presence' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, update_presence: nil)
      allow(provider_double).to receive(:update_presence).with('online')
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.update_presence('online')

      expect(provider_double).to have_received(:update_presence)
    end

    it 'does not call method if provider service does not implement it' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect do
        channel.update_presence('online')
      end.not_to raise_error
    end
  end

  describe '#read_messages' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', provider_config: { mark_as_read: true }, validate_provider_config: false, sync_templates: false)
    end
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, source_id: '3EB0READ0001') }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(provider_double).to receive(:read_messages).with([message], recipient_id: conversation.contact.identifier)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(provider_double).to have_received(:read_messages)
    end

    it 'call method when the provider config mark_as_read is nil' do
      channel.update!(provider_config: {})
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(provider_double).to receive(:read_messages).with([message], recipient_id: conversation.contact.identifier)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(provider_double).to have_received(:read_messages)
    end

    # The provider echoes this receipt back as an inbound one, and the marker is what stops
    # the inbound handlers from reading it as a device of this account opening the chat.
    it 'marks the messages so the provider echo is not read back as a device read' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(Whatsapp::SelfReadReceipts.acknowledged(conversation, [message.source_id])).to include(message.source_id)
      Redis::Alfred.delete(Whatsapp::SelfReadReceipts.key(conversation, message.source_id))
    end

    # The echo is a multi-device artifact, so a business-API inbox has no device to hear it
    # from and no inbound handler that reads the marker. Writing one per message there is a
    # Redis key per message of a backlog that nothing ever looks at.
    it 'leaves no marker for a provider that is not a paired phone' do
      channel.update!(provider: 'whatsapp_cloud',
                      provider_config: { mark_as_read: true, api_key: 'k', phone_number_id: '1', business_account_id: '2', app_secret: 's' })
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService, read_messages: nil)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(Whatsapp::SelfReadReceipts.acknowledged(conversation, [message.source_id])).to be_empty
    end

    # Z-API is a paired phone, so the echo does reach it, but its status callback only moves a
    # message's status and never `agent_last_seen_at`. Nothing reads the marker back, so every
    # key written for it expires unread.
    it 'leaves no marker for a paired phone whose inbound path never reads it' do
      channel.update!(provider: 'zapi', provider_config: { mark_as_read: true, api_key: 'k', instance_id: '1', token: 't' })
      provider_double = instance_double(Whatsapp::Providers::WhatsappZapiService, read_messages: nil)
      allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new).and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(Whatsapp::SelfReadReceipts.acknowledged(conversation, [message.source_id])).to be_empty
    end

    it 'leaves no marker when the inbox has mark_as_read off' do
      channel.update!(provider_config: { mark_as_read: false })

      channel.read_messages([message], conversation: conversation)

      expect(Whatsapp::SelfReadReceipts.acknowledged(conversation, [message.source_id])).to be_empty
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'default')

      expect do
        channel.read_messages([message], conversation: conversation)
      end.not_to raise_error
    end

    it 'does not call method if provider config mark_as_read is false' do
      channel.update!(provider_config: { mark_as_read: false })

      expect do
        channel.read_messages([message], conversation: conversation)
      end.not_to raise_error
    end
  end

  describe '#unread_conversation' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }

    it 'calls provider service method' do
      message = create(:message, conversation: conversation, message_type: 'incoming')
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, unread_message: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)
      allow(provider_double).to receive(:unread_message).with(conversation.contact.phone_number, [message])

      channel.unread_conversation(conversation)

      expect(provider_double).to have_received(:unread_message)
    end

    it 'does not call method if provider service does not implement it' do
      # NOTE: This message ensures that there are messages but the provider does not implement the method.
      create(:message, conversation: conversation, message_type: 'incoming')

      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)

      expect do
        channel.unread_conversation(conversation)
      end
        .not_to raise_error
    end

    it 'does not call method if there are no messages' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, unread_message: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)
      allow(provider_double).to receive(:unread_message)

      channel.unread_conversation(conversation)

      expect(provider_double).not_to have_received(:unread_message)
    end
  end

  describe '#received_messages' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }
    let(:messages) { [create(:message, conversation: conversation)] }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, received_messages: nil)
      allow(provider_double).to receive(:received_messages).with(conversation.contact.identifier, messages)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.received_messages(messages, conversation)

      expect(provider_double).to have_received(:received_messages)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud', provider_config: channel.provider_config.merge('app_secret' => 'test_app_secret'))

      expect do
        channel.received_messages(messages, conversation)
      end.not_to raise_error
    end
  end

  describe '#on_whatsapp' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }
    let(:phone_number) { '+123456789' }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, on_whatsapp: nil)
      allow(provider_double).to receive(:on_whatsapp).with(phone_number)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.on_whatsapp(phone_number)

      expect(provider_double).to have_received(:on_whatsapp)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud', provider_config: channel.provider_config.merge('app_secret' => 'test_app_secret'))

      expect do
        channel.on_whatsapp(phone_number)
      end.not_to raise_error
    end
  end

  describe '#delete_message' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:contact) { create(:contact, identifier: '+551187654321') }
    let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, contact: contact) }
    let(:conversation) { create(:conversation, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox) }
    let(:message) { create(:message, conversation: conversation, inbox: channel.inbox, source_id: 'msg_123', message_type: :outgoing) }

    it 'calls provider service delete_message method for baileys' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.identifier, message)
    end

    it 'calls provider service delete_message method for zapi with phone_number' do
      contact.update!(phone_number: '+551199999999')
      channel.update!(provider: 'zapi')
      provider_double = instance_double(Whatsapp::Providers::WhatsappZapiService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.phone_number, message)
    end

    it 'calls provider service delete_message method for zapi falling back to identifier when phone_number is blank' do
      channel.update!(provider: 'zapi')
      provider_double = instance_double(Whatsapp::Providers::WhatsappZapiService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.identifier, message)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud', provider_config: channel.provider_config.merge('app_secret' => 'test_app_secret'))

      expect do
        channel.delete_message(message, conversation: conversation)
      end.not_to raise_error
    end
  end

  describe 'callbacks' do
    describe '#disconnect_channel_provider' do
      context 'when provider implements the method' do
        let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
        let(:disconnect_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}" }

        it 'destroys the channel on successful disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 200)

          channel.destroy!

          expect(channel).to be_destroyed
        end

        it 'destroys the channel on failure to disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 404, body: 'error message')
          # NOTE: On failure, `setup_channel_provider` is called, so we re-stub to avoid errors
          stub_request(:post, disconnect_url).to_return(status: 200)

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end

      context 'when provider does not implement the method' do
        let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }

        before do
          stub_request(:delete, "https://graph.facebook.com/v22.0/#{channel.provider_config['business_account_id']}/subscribed_apps")
            .to_return(status: 200, body: '', headers: {})
          stub_request(:post, "https://graph.facebook.com/v22.0/#{channel.provider_config['phone_number_id']}")
            .with(body: { webhook_configuration: { override_callback_uri: '' } }.to_json)
            .to_return(status: 200, body: '', headers: {})
          stub_request(:post, "https://graph.facebook.com/v22.0/#{channel.provider_config['phone_number_id']}/deregister")
            .to_return(status: 200, body: '', headers: {})
        end

        it 'does not invoke callback' do
          expect(channel).not_to receive(:disconnect_channel_provider)

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end
    end
  end

  describe '#update_provider_connection!' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
    end

    # The dashboard keeps the inbox list in IndexedDB and fetches it again only when the
    # account's inbox key moves. A browser that missed the live event (a closed tab, a
    # sleeping laptop, a cable that reconnected) went on showing a dropped session as
    # connected, because a connection change never moved the key (#856).
    def inbox_key = channel.inbox.account.reload.cache_keys[:inbox]

    it 'moves the account inbox key when the connection changes' do
      channel.update_provider_connection!(connection: 'open')
      before = travel(1.second) { inbox_key }

      travel(2.seconds) { channel.update_provider_connection!(connection: 'close') }

      expect(inbox_key).not_to eq(before)
    end

    it 'moves the account inbox key when the connection is cleared' do
      channel.update_provider_connection!(connection: 'open')
      before = travel(1.second) { inbox_key }

      travel(2.seconds) { channel.update_provider_connection!({}) }

      expect(inbox_key).not_to eq(before)
    end

    # A new QR arrives every few seconds while a phone is pairing; touching the inbox for
    # each one would invalidate every agent's cached inbox list for nothing.
    it 'leaves the inbox alone when only the rest of the connection changes' do
      channel.update_provider_connection!(connection: 'connecting', qr_data_url: 'qr-1')
      inbox = channel.inbox
      before = travel(1.second) { inbox_key }

      expect do
        travel(2.seconds) { channel.update_provider_connection!(connection: 'connecting', qr_data_url: 'qr-2') }
      end.not_to(change { inbox.reload.updated_at })
      expect(inbox_key).to eq(before)
    end

    it 'persists the new connection status' do
      channel.update_provider_connection!(connection: 'open')

      expect(channel.reload.provider_connection).to eq('connection' => 'open')
    end

    it 'pushes a targeted event through the sync dispatcher only' do
      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      # A change of `connection` also moves the account's inbox key, which announces itself
      # with its own event; this one is about the targeted push.
      allow(sync_dispatcher).to receive(:dispatch)

      channel.update_provider_connection!(connection: 'open')

      expect(sync_dispatcher).to have_received(:dispatch).with(
        Events::Types::INBOX_PROVIDER_CONNECTION_UPDATED,
        anything,
        hash_including(inbox: channel.inbox, provider_connection: { 'connection' => 'open' })
      ).once
    end

    it 'does not push or save when the connection status is unchanged' do
      channel.update_provider_connection!(connection: 'open')

      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).not_to receive(:dispatch)
      expect(channel).not_to receive(:save!)

      channel.update_provider_connection!(connection: 'open')
    end

    it 'treats a nil payload as a no-op instead of raising' do
      expect { channel.update_provider_connection!(nil) }.not_to raise_error
      expect(channel.reload.provider_connection).to eq({})
    end
  end

  describe '#update_reachout_time_lock!' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_connection: { 'connection' => 'open', 'epoch' => 7 })
    end

    it 'merges the lock without touching connection or epoch' do
      channel.update_reachout_time_lock!({ is_active: true, time_enforcement_ends: '2026-06-19T21:52:39.000Z' })

      expect(channel.reload.provider_connection).to eq(
        'connection' => 'open',
        'epoch' => 7,
        'reachout_time_lock' => { 'is_active' => true, 'time_enforcement_ends' => '2026-06-19T21:52:39.000Z' }
      )
    end

    it 'broadcasts the updated provider_connection' do
      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).to receive(:dispatch).with(
        Events::Types::INBOX_PROVIDER_CONNECTION_UPDATED,
        anything,
        hash_including(inbox: channel.inbox)
      )

      channel.update_reachout_time_lock!({ is_active: true })
    end

    it 'is a no-op when the lock is unchanged' do
      channel.update_reachout_time_lock!({ is_active: true })

      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).not_to receive(:dispatch)

      channel.update_reachout_time_lock!({ is_active: true })
    end

    it 'returns without raising or broadcasting when passed nil (404/fetch error)' do
      expect(channel.provider_connection).to be_present # realize the record before arming the dispatch guard

      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).not_to receive(:dispatch)

      expect { channel.update_reachout_time_lock!(nil) }.not_to raise_error
    end
  end

  describe '#update_new_chat_cap!' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_connection: { 'connection' => 'open', 'epoch' => 7 })
    end

    it 'persists only the UI-relevant keys, dropping server_sent_timestamp' do
      channel.update_new_chat_cap!({
                                     capping_status: 'CAPPED',
                                     ote_status: 'ELIGIBLE',
                                     mv_status: 'NOT_ELIGIBLE',
                                     total_quota: 100,
                                     used_quota: 100,
                                     cycle_start_timestamp: '1781640000',
                                     cycle_end_timestamp: '1781699999',
                                     server_sent_timestamp: '1781645846'
                                   })

      expect(channel.reload.provider_connection).to eq(
        'connection' => 'open',
        'epoch' => 7,
        'new_chat_cap' => {
          'capping_status' => 'CAPPED',
          'ote_status' => 'ELIGIBLE',
          'mv_status' => 'NOT_ELIGIBLE',
          'total_quota' => 100,
          'used_quota' => 100,
          'cycle_start_timestamp' => '1781640000',
          'cycle_end_timestamp' => '1781699999'
        }
      )
    end

    it 'is a no-op when the cap is unchanged' do
      cap = { capping_status: 'FIRST_WARNING', total_quota: 100, used_quota: 50 }
      channel.update_new_chat_cap!(cap)

      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).not_to receive(:dispatch)

      channel.update_new_chat_cap!(cap)
    end

    it 'returns without raising or broadcasting when passed nil (404/fetch error)' do
      expect(channel.provider_connection).to be_present # realize the record before arming the dispatch guard

      sync_dispatcher = Rails.configuration.dispatcher.sync_dispatcher
      expect(sync_dispatcher).not_to receive(:dispatch)

      expect { channel.update_new_chat_cap!(nil) }.not_to raise_error
    end
  end

  describe '#provider_connection_data' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_connection: {
                                  'connection' => 'open',
                                  'qr_data_url' => 'data:image/png;base64,test',
                                  'error' => 'some_error'
                                })
    end

    context 'when user is an administrator' do
      it 'includes qr_data_url and error in the response' do
        account_user = create(:account_user, account: channel.account, role: :administrator)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({
                             connection: 'open',
                             qr_data_url: 'data:image/png;base64,test',
                             error: 'some_error'
                           })
      end
    end

    context 'when user is not an administrator' do
      it 'excludes qr_data_url and error from the response' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({ connection: 'open' })
      end
    end

    context 'when Current.account_user is nil' do
      it 'excludes qr_data_url and error from the response' do
        allow(Current).to receive(:account_user).and_return(nil)

        data = channel.provider_connection_data

        expect(data).to eq({ connection: 'open' })
      end
    end

    context 'when a reach-out time-lock is present' do
      let(:channel) do
        create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                  provider_connection: {
                                    'connection' => 'open',
                                    'reachout_time_lock' => { 'is_active' => true, 'time_enforcement_ends' => '2026-06-19T21:52:39.000Z' }
                                  })
      end

      it 'exposes the lock to non-administrators (agents see the banner too)' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({
                             connection: 'open',
                             reachout_time_lock: { 'is_active' => true, 'time_enforcement_ends' => '2026-06-19T21:52:39.000Z' }
                           })
      end
    end

    context 'when a send stall is present' do
      let(:channel) do
        create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                  provider_connection: {
                                    'connection' => 'open',
                                    'send_stall' => { 'consecutive_timeouts' => 3, 'action' => 'suppressed' }
                                  })
      end

      # The agent is the one whose replies are silently going nowhere, and the connection
      # still reads 'open', so without this there is nothing in their view to warn them.
      # Nothing in the payload is credential-sensitive, unlike the QR.
      it 'exposes the stall to non-administrators' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({
                             connection: 'open',
                             send_stall: { 'consecutive_timeouts' => 3, 'action' => 'suppressed' }
                           })
      end
    end

    context 'when the connection is being rerouted' do
      let(:channel) do
        create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                  provider_connection: { 'connection' => 'reconnecting', 'rerouting' => true })
      end

      # An agent gets no error string, so this is the only thing telling a proxy change,
      # which comes back on its own, apart from an outage.
      it 'exposes the reroute to non-administrators' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        expect(channel.provider_connection_data).to eq({ connection: 'reconnecting', rerouting: true })
      end
    end

    context 'when a new-chat cap is present' do
      let(:channel) do
        create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                  provider_connection: {
                                    'connection' => 'open',
                                    'new_chat_cap' => { 'capping_status' => 'CAPPED', 'total_quota' => 100, 'used_quota' => 100 }
                                  })
      end

      it 'exposes the cap to non-administrators' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({
                             connection: 'open',
                             new_chat_cap: { 'capping_status' => 'CAPPED', 'total_quota' => 100, 'used_quota' => 100 }
                           })
      end
    end
  end

  describe '#convert_provider!' do
    let(:channel) do
      create(:channel_whatsapp,
             provider: 'baileys',
             provider_connection: { 'connection' => 'open' },
             validate_provider_config: false,
             sync_templates: false)
    end

    let(:new_cloud_config) do
      { 'api_key' => 'new_cloud_key', 'phone_number_id' => 'new_phone_id', 'business_account_id' => 'new_waba_id', 'app_secret' => 'new_secret' }
    end

    before do
      stub_request(:delete, "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}")
        .to_return(status: 200)
      stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/.*message_templates})
        .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, %r{graph\.facebook\.com/v\d+\.\d+/.*/subscribed_apps})
        .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, %r{graph\.facebook\.com/v\d+\.\d+/\d+\z})
        .with(body: { webhook_configuration: { override_callback_uri: '' } }.to_json)
        .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, %r{graph\.facebook\.com/v\d+\.\d+/\d+/deregister})
        .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      webhook_setup_service = instance_double(Whatsapp::WebhookSetupService, perform: nil)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup_service)
    end

    it 'swaps provider and provider_config atomically' do
      channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)

      channel.reload
      expect(channel.provider).to eq('whatsapp_cloud')
      expect(channel.provider_config).to include(new_cloud_config)
      expect(channel.provider_config).not_to have_key('provider_url')
    end

    it 'clears provider_connection and message_templates' do
      channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)

      channel.reload
      expect(channel.provider_connection).to eq({})
      expect(channel.message_templates).to eq({})
      expect(channel.message_templates_last_updated).to be_nil
    end

    it 'calls disconnect on the old provider when supported' do
      disconnect_url = "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}"

      channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)

      expect(WebMock).to have_requested(:delete, disconnect_url)
    end

    it 'does not raise when the old provider has no disconnect method' do
      cloud_channel = create(:channel_whatsapp,
                             provider: 'whatsapp_cloud',
                             provider_config: {
                               'source' => 'embedded_signup',
                               'api_key' => 'old_key',
                               'phone_number_id' => 'old_phone_id',
                               'business_account_id' => 'old_waba_id'
                             },
                             validate_provider_config: false,
                             sync_templates: false)

      expect do
        cloud_channel.convert_provider!(
          new_provider: 'baileys',
          new_provider_config: { 'provider_url' => 'https://baileys.api', 'api_key' => 'k' }
        )
      end.not_to raise_error
    end

    it 'rolls back and raises when the new provider config is invalid, leaving the old provider session untouched' do
      # The factory installs a singleton `validate_provider_config` stub that
      # bypasses validation; reload from DB to get a clean instance.
      fresh_channel = described_class.find(channel.id)
      cloud_service = instance_double(Whatsapp::Providers::WhatsappCloudService, validate_provider_config?: false)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(cloud_service)
      disconnect_url = "#{fresh_channel.provider_config['provider_url']}/connections/#{fresh_channel.phone_number}"

      expect do
        fresh_channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: { 'api_key' => 'bad' })
      end.to(raise_error { |error| expect(error.class.name).to eq('ActiveRecord::RecordInvalid') })

      fresh_channel.reload
      expect(fresh_channel.provider).to eq('baileys')
      expect(WebMock).not_to have_requested(:delete, disconnect_url)
    end

    it 'triggers webhook setup on the new provider when auto-setup applies' do
      webhook_setup_service = instance_double(Whatsapp::WebhookSetupService, perform: nil)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup_service)

      channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)

      expect(Whatsapp::WebhookSetupService).to have_received(:new).with(channel, 'new_waba_id', 'new_cloud_key', is_coexistence: nil)
      expect(webhook_setup_service).to have_received(:perform)
    end

    it 'does not trigger webhook setup when the new provider does not auto-setup' do
      cloud_channel = create(:channel_whatsapp,
                             provider: 'whatsapp_cloud',
                             provider_config: {
                               'source' => 'embedded_signup',
                               'api_key' => 'old_key',
                               'phone_number_id' => 'old_phone_id',
                               'business_account_id' => 'old_waba_id'
                             },
                             validate_provider_config: false,
                             sync_templates: false)
      allow(Whatsapp::WebhookSetupService).to receive(:new)

      cloud_channel.convert_provider!(
        new_provider: 'baileys',
        new_provider_config: { 'provider_url' => 'https://baileys.api', 'api_key' => 'k' }
      )

      expect(Whatsapp::WebhookSetupService).not_to have_received(:new)
    end

    it 'rejects no-op conversions targeting the current provider' do
      original_templates_count = channel.message_templates.count

      expect do
        channel.convert_provider!(new_provider: 'baileys', new_provider_config: channel.provider_config)
      end.to(raise_error { |error| expect(error.class.name).to eq('ActiveRecord::RecordInvalid') })

      channel.reload
      expect(channel.provider_connection).to eq('connection' => 'open')
      expect(channel.message_templates.count).to eq(original_templates_count)
    end

    it 'aborts and does not persist the new provider when the disconnect fails' do
      original_templates_count = channel.message_templates.count
      baileys_service = instance_double(Whatsapp::Providers::WhatsappBaileysService)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
      allow(baileys_service).to receive(:disconnect_channel_provider).and_raise(StandardError, 'boom')

      expect do
        channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)
      end.to(raise_error { |error| expect(error.class.name).to eq('StandardError') })

      channel.reload
      expect(channel.provider).to eq('baileys')
      expect(channel.message_templates.count).to eq(original_templates_count)
    end

    # An installation with no Baileys provider at all has no session it could end, so
    # refusing the conversion there left the inbox stuck on Baileys forever (#745). With
    # a provider configured and not answering, the session may still be alive, and the
    # refusal above stands.
    context 'when no Baileys provider is configured anywhere' do
      before do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)
        channel.update!(provider_config: {})
        allow(Rails.logger).to receive(:warn)
      end

      it 'converts without trying to end the old session, and says so' do
        channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)

        expect(channel.reload.provider).to eq('whatsapp_cloud')
        expect(WebMock).not_to have_requested(:delete, %r{/connections/})
        expect(Rails.logger).to have_received(:warn).with(/no baileys provider is configured/i)
      end
    end

    context 'when the inbox names its own Baileys provider and it does not answer' do
      before do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)
        channel.update!(provider_config: { 'provider_url' => 'http://inbox-baileys.test', 'api_key' => 'k' })
        stub_request(:delete, %r{inbox-baileys\.test/connections/}).to_raise(Errno::ECONNREFUSED)
      end

      it 'still refuses, because that session may be alive' do
        expect do
          channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(channel.reload.provider).to eq('baileys')
      end
    end

    it 'swallows and logs errors raised by post-conversion template sync' do
      # Bypass both the factory's singleton `sync_templates` stub and validation,
      # so we can observe the rescue branch on the real instance.
      fresh_channel = described_class.find(channel.id)
      cloud_service = instance_double(
        Whatsapp::Providers::WhatsappCloudService,
        validate_provider_config?: true
      )
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(cloud_service)
      # Some provider services stamp `message_templates_last_updated` before
      # the remote fetch; emulate that by setting the timestamp right before
      # the raise, so the rescue must reset it to avoid a "synced" state.
      allow(fresh_channel).to receive(:sync_templates) do
        fresh_channel.mark_message_templates_updated
        raise StandardError, 'boom'
      end
      allow(Rails.logger).to receive(:error)

      expect do
        fresh_channel.convert_provider!(new_provider: 'whatsapp_cloud', new_provider_config: new_cloud_config)
      end.not_to raise_error

      fresh_channel.reload
      expect(fresh_channel.provider).to eq('whatsapp_cloud')
      expect(fresh_channel.provider_connection).to eq({})
      expect(fresh_channel.message_templates).to eq({})
      expect(fresh_channel.message_templates_last_updated).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Post-conversion template sync failed.*boom/)
    end

    context 'when converting from whatsapp_cloud to baileys' do
      let(:cloud_channel) do
        create(:channel_whatsapp,
               provider: 'whatsapp_cloud',
               provider_config: {
                 'source' => 'embedded_signup',
                 'api_key' => 'old_key',
                 'phone_number_id' => 'old_phone_id',
                 'business_account_id' => 'old_waba_id'
               },
               validate_provider_config: false,
               sync_templates: false)
      end
      let(:new_baileys_config) { { 'provider_url' => 'https://baileys.api', 'api_key' => 'new_baileys_key' } }

      before do
        stub_request(:delete, %r{https://baileys\.api/connections/.*})
          .to_return(status: 200)
      end

      it 'invokes WebhookTeardownService on the old cloud channel before swapping' do
        teardown_service = instance_double(Whatsapp::WebhookTeardownService, perform: nil)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(cloud_channel).and_return(teardown_service)

        cloud_channel.convert_provider!(new_provider: 'baileys', new_provider_config: new_baileys_config)

        expect(Whatsapp::WebhookTeardownService).to have_received(:new).with(cloud_channel)
        expect(teardown_service).to have_received(:perform)
      end

      it 'swallows and logs errors raised by pre-conversion webhook teardown' do
        teardown_service = instance_double(Whatsapp::WebhookTeardownService)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(cloud_channel).and_return(teardown_service)
        allow(teardown_service).to receive(:perform).and_raise(StandardError, 'teardown boom')
        allow(Rails.logger).to receive(:error)

        expect do
          cloud_channel.convert_provider!(new_provider: 'baileys', new_provider_config: new_baileys_config)
        end.not_to raise_error

        cloud_channel.reload
        expect(cloud_channel.provider).to eq('baileys')
        expect(Rails.logger).to have_received(:error).with(/Pre-conversion webhook teardown failed.*teardown boom/)
      end

      it 'resets the teardown guard so a subsequent destroy still tears down webhooks' do
        teardown_service = instance_double(Whatsapp::WebhookTeardownService, perform: nil)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).and_return(teardown_service)

        cloud_channel.convert_provider!(new_provider: 'baileys', new_provider_config: new_baileys_config)
        # The convert path no longer matches the teardown branch (provider is
        # now baileys), so destroy! hitting teardown_webhooks again proves the
        # `@webhook_teardown_initiated` guard was reset by the ensure block.
        cloud_channel.destroy!

        # One teardown from the pre-conversion branch, one from destroy.
        expect(teardown_service).to have_received(:perform).twice
      end
    end
  end

  describe '#sync_group' do
    it 'delegates to provider_service when it supports sync_group' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
      conversation = create(:conversation, inbox: channel.inbox, account: channel.account)
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, sync_group: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.sync_group(conversation)

      expect(provider_double).to have_received(:sync_group).with(conversation, soft: false)
    end

    it 'does nothing when provider_service does not support sync_group' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      conversation = create(:conversation, inbox: channel.inbox, account: channel.account)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect(channel.sync_group(conversation)).to be_nil
    end
  end

  describe '#supports_reactions?' do
    it 'returns true for whatsapp_cloud provider' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      expect(channel.supports_reactions?).to be(true)
    end

    it 'returns true for baileys provider' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
      expect(channel.supports_reactions?).to be(true)
    end

    it 'returns true for zapi provider' do
      channel = create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false)
      expect(channel.supports_reactions?).to be(true)
    end

    it 'returns false for default (360dialog) provider' do
      channel = create(:channel_whatsapp, provider: 'default', validate_provider_config: false, sync_templates: false)
      expect(channel.supports_reactions?).to be(false)
    end
  end

  describe '#voice_enabled?' do
    let(:account) { create(:account) }

    before { account.enable_features!('channel_voice') }

    it 'returns true for embedded-signup whatsapp_cloud channels with calling_enabled' do
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(provider_config: channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true))

      expect(channel.voice_enabled?).to be true
    end

    it 'returns true for manual whatsapp_cloud channels with calling_enabled' do
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(provider_config: channel.provider_config.merge('source' => 'manual', 'app_secret' => 'secret', 'calling_enabled' => true))

      expect(channel.voice_enabled?).to be true
    end

    it 'returns false for default-provider channels (360dialog) even with calling_enabled' do
      channel = create(:channel_whatsapp, account: account, provider: 'default',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(provider_config: channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true))

      expect(channel.voice_enabled?).to be false
    end

    it 'returns false when the channel_voice feature is disabled on the account' do
      account.disable_features!('channel_voice')
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(provider_config: channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true))

      expect(channel.voice_enabled?).to be false
    end
  end

  describe '#inbound_calls_enabled?' do
    let(:account) { create(:account) }

    it 'returns true by default when nothing has been toggled' do
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      expect(channel.inbound_calls_enabled?).to be true
    end

    it 'returns false only when explicitly disabled in provider_config' do
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(provider_config: channel.provider_config.merge('inbound_calls_enabled' => false))

      expect(channel.inbound_calls_enabled?).to be false
    end
  end
end
