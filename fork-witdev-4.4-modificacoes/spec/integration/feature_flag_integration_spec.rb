# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feature Flag Integration' do
  let(:account) { create(:account) }
  let(:another_account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  let(:rich_payload) do
    {
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => 'Feature Flag Test Product',
          'subtitle' => 'Testing feature flag integration'
        }
      ]
    }
  end

  before do
    # Mock Instagram API calls
    stub_request(:post, /graph\.instagram\.com/)
      .to_return(status: 200, body: { message_id: 'test_message_id' }.to_json)

    # Mock GlobalConfig for human agent tag
    allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                        .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => false })
  end

  describe 'global feature flag behavior' do
    context 'when global flag is enabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
      end

      it 'enables feature for all accounts' do
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be true
      end

      it 'enables Instagram Rich Message Service mirroring' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items']).to be_present
      end
    end

    context 'when global flag is disabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })
      end

      it 'disables feature for all accounts' do
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be false
      end

      it 'skips Instagram Rich Message Service mirroring' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('text')
        expect(message.content).to eq('Test message')
      end
    end
  end

  describe 'account-scoped feature flag behavior' do
    before do
      # Set global flag to false
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })
    end

    context 'when account has flag enabled' do
      before do
        AccountFeatureFlag.create!(
          account: account,
          flag_name: 'SOCIALWISE_RICH_DASHBOARD',
          enabled: true
        )
      end

      it 'enables feature for specific account only' do
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be false
      end

      it 'enables Instagram Rich Message Service mirroring for specific account' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items']).to be_present
      end
    end

    context 'when account has flag disabled' do
      before do
        AccountFeatureFlag.create!(
          account: account,
          flag_name: 'SOCIALWISE_RICH_DASHBOARD',
          enabled: false
        )
      end

      it 'disables feature for specific account' do
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false
      end

      it 'skips Instagram Rich Message Service mirroring for specific account' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('text')
        expect(message.content).to eq('Test message')
      end
    end
  end

  describe 'gradual rollout scenarios' do
    before do
      # Set global flag to false for gradual rollout
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })
    end

    it 'supports gradual rollout by enabling flag for specific accounts' do
      # Initially, no accounts have the feature
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be false

      # Enable for first account (gradual rollout phase 1)
      Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)

      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be false

      # Enable for second account (gradual rollout phase 2)
      Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, another_account.id, true)

      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be true
    end

    it 'supports bulk operations for gradual rollout' do
      account_ids = [account.id, another_account.id]

      # Bulk enable for multiple accounts
      AccountFeatureFlag.bulk_enable('SOCIALWISE_RICH_DASHBOARD', account_ids)

      account_ids.each do |account_id|
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)).to be true
      end

      # Bulk disable for rollback
      AccountFeatureFlag.bulk_disable('SOCIALWISE_RICH_DASHBOARD', account_ids)

      account_ids.each do |account_id|
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)).to be false
      end
    end
  end

  describe 'rollback scenarios' do
    context 'global rollback' do
      it 'supports instant rollback via global flag toggle' do
        # Initially enabled globally
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true

        # Simulate rollback by disabling global flag
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })

        # Clear cache to simulate config change
        Feature.clear_cache

        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false
      end
    end

    context 'account-specific rollback' do
      before do
        # Set global flag to true
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
      end

      it 'supports account-specific rollback by setting account flag to false' do
        # Initially enabled globally
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true

        # Disable for specific account (account-specific rollback)
        Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, false)

        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, another_account.id)).to be true
      end

      it 'supports account-specific rollback by removing account flag' do
        # Set account flag to true
        Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true

        # Remove account flag (falls back to global)
        Feature.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id)
        expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true # Falls back to global
      end
    end
  end

  describe 'caching and performance' do
    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'caches feature flag values for performance' do
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      # First call should hit database
      expect(AccountFeatureFlag).to receive(:find_by).once.and_call_original
      result1 = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)

      # Second call should use cache
      expect(AccountFeatureFlag).not_to receive(:find_by)
      result2 = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)

      expect(result1).to eq(result2)
      expect(result1).to be true
    end

    it 'clears cache when flags are updated' do
      flag = AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      # Cache the value
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be false

      # Update the flag
      flag.update!(enabled: true)

      # Should return updated value (cache cleared)
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
    end
  end

  describe 'error handling' do
    it 'handles missing account gracefully' do
      non_existent_account_id = 99999

      expect { Feature.get(:SOCIALWISE_RICH_DASHBOARD, non_existent_account_id) }.not_to raise_error
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, non_existent_account_id)).to be_a(Boolean)
    end

    it 'handles invalid flag names gracefully' do
      expect { Feature.get(:INVALID_FLAG, account.id) }.not_to raise_error
      expect(Feature.get(:INVALID_FLAG, account.id)).to be false
    end

    it 'handles database errors gracefully' do
      allow(AccountFeatureFlag).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      # Should fall back to global config
      expect(Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)).to be true
    end
  end

  describe 'frontend integration' do
    let(:user) { create(:user) }

    before do
      create(:account_user, user: user, account: account)
    end

    it 'exposes feature flag to frontend via dashboard controller' do
      allow(GlobalConfig).to receive(:get).and_call_original
      allow(GlobalConfig).to receive(:get).with(
        'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
        'INSTALLATION_NAME',
        'WIDGET_BRAND_URL', 'TERMS_URL',
        'BRAND_URL', 'BRAND_NAME',
        'PRIVACY_URL',
        'DISPLAY_MANIFEST',
        'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
        'CHATWOOT_INBOX_TOKEN',
        'API_CHANNEL_NAME',
        'API_CHANNEL_THUMBNAIL',
        'ANALYTICS_TOKEN',
        'DIRECT_UPLOADS_ENABLED',
        'HCAPTCHA_SITE_KEY',
        'LOGOUT_REDIRECT_LINK',
        'DISABLE_USER_PROFILE_UPDATE',
        'DEPLOYMENT_ENV',
        'INSTALLATION_PRICING_PLAN',
        'SOCIALWISE_RICH_DASHBOARD'
      ).and_return({
        'SOCIALWISE_RICH_DASHBOARD' => 'true'
      }.with_indifferent_access)

      # Simulate dashboard request
      controller = DashboardController.new
      controller.send(:set_global_config)

      expect(controller.instance_variable_get(:@global_config)).to include(
        'SOCIALWISE_RICH_DASHBOARD' => 'true'
      )
    end
  end
end