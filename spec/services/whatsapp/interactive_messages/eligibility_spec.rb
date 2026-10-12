require 'rails_helper'

RSpec.describe Whatsapp::InteractiveMessages::Eligibility do
  subject(:eligibility) { described_class.new(conversation) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: provider, validate_provider_config: false, sync_templates: false)
  end
  let(:provider) { 'whatsapp_cloud' }
  let(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: '+15550000001') }
  let(:contact_inbox) do
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '15550000001')
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }

  before do
    conversation.account.enable_features!(*described_class::TYPE_FEATURES.values)
    create(:message, :incoming, conversation: conversation, account: conversation.account, inbox: conversation.inbox)
  end

  it 'allows an exact normalized recipient match without returning configured recipients' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      capability = eligibility.capabilities

      expect(capability.dig(:interactive_types, :button)).to include(implemented: true, available: true)
      expect(capability.dig(:interactive_types, :list)).to include(
        implemented: true,
        available: true,
        limits: include(body_max_length: 4096, section_max_count: 10, row_max_count: 10)
      )
      expect(capability.dig(:recipient, :test_allowlisted)).to be(true)
      expect(capability[:send_lanes]).to contain_exactly('service', 'template')
      expect(capability.to_json).not_to include('+15550000001', '+15550000002')
    end
  end

  it 'keeps implementation and account enablement separate for every planned type' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      types = eligibility.capabilities[:interactive_types]

      expect(types[:button]).to include(implemented: true, enabled: true, available: true, unavailable_reasons: [])
      expect(types[:list]).to include(
        implemented: true,
        enabled: true,
        available: true,
        unavailable_reasons: []
      )
      expect(types[:location_request_message]).to include(implemented: true, existing: true, available: true)
      expect(types.keys).to contain_exactly(:button, :list, :carousel, :cta_url, :location_request_message)
    end
  end

  it 'keeps the existing location request independent from the four new account flags' do
    conversation.account.disable_features!(*described_class::TYPE_FEATURES.values)

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      capability = eligibility.capabilities.dig(:interactive_types, :location_request_message)

      expect(capability).to include(implemented: true, existing: true, available: true, unavailable_reasons: [])
      expect(capability).not_to have_key(:enabled)
    end
  end

  it 'defaults an inbox without a stored mode or test allowlist to production' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '' do
      expect(eligibility.capabilities).to include(
        account_mode: 'production',
        recipient: { test_allowlisted: nil, service_window_open: true }
      )
    end
  end

  it 'reports every concurrent contextual restriction while preserving the scalar reason' do
    conversation.account.disable_features!('whatsapp_interactive_button')
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      capability = eligibility.capabilities.dig(:interactive_types, :button)

      expect(capability).to include(
        available: false,
        unavailable_reason: 'temporarily_disabled',
        unavailable_reasons: %w[temporarily_disabled service_window_closed test_recipient_not_allowlisted]
      )
      expect(eligibility.reason('button')).to eq('temporarily_disabled')
      expect { eligibility.ensure_available!('button') }
        .to raise_error(Whatsapp::InteractiveMessages::EligibilityError, 'temporarily_disabled')
    end
  end

  it 'changes only the capability controlled by one account flag' do
    conversation.account.disable_features!('whatsapp_interactive_button')

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      types = eligibility.capabilities[:interactive_types]

      expect(types[:button]).to include(enabled: false, available: false, unavailable_reason: 'temporarily_disabled')
      expect(types[:list]).to include(enabled: true, available: true, unavailable_reasons: [])
    end
  end

  it 'returns independently stored readiness facts and leaves unsourced facts unknown' do
    whatsapp_channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
      phone_number_health: {
        'account_mode' => 'TEST',
        'waba_review_status' => 'approved',
        'business_verification_status' => 'not_verified',
        'message_quality_status' => 'insufficient',
        'quality_rating' => 'RED',
        'status' => 'CONNECTED'
      }
    )

    capability = eligibility.capabilities

    expect(capability).to include(
      account_mode: 'test',
      waba_review_status: 'approved',
      business_verification_status: 'not_verified',
      message_quality_status: 'insufficient',
      quality_rating: 'RED',
      phone_number_status: 'CONNECTED',
      production_phone_onboarded: nil,
      billing_configured: nil
    )
  end

  it 'reports distinct concurrent product exclusions from independently stored facts' do
    whatsapp_channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
      phone_number_health: {
        'business_verification_status' => 'not_verified',
        'message_quality_status' => 'insufficient',
        'catalog_linked' => false,
        'calling_enabled' => false,
        'direct_send_enrollment_status' => 'not_enrolled',
        'address_market_eligible' => false,
        'payment_market_eligible' => false,
        'payment_transaction_integration_configured' => false,
        'order_market_eligible' => false,
        'order_transaction_integration_configured' => false
      }
    )

    exclusions = eligibility.capabilities[:excluded_capabilities]

    expect(exclusions.transform_values { |value| value[:unavailable_reasons] }).to eq(
      flow: %w[business_not_verified message_quality_insufficient],
      catalog: ['catalog_not_linked'],
      calling: ['calling_not_enabled'],
      direct_send: ['not_enrolled'],
      address: ['market_ineligible'],
      payment: %w[market_ineligible transaction_integration_missing],
      order: %w[market_ineligible transaction_integration_missing]
    )
    expect(exclusions.values).to all(include(readiness_known: true))
  end

  it 'keeps unknown exclusion facts explicit instead of inferring reasons' do
    exclusions = eligibility.capabilities[:excluded_capabilities]

    expect(exclusions[:flow]).to include(
      readiness: { business_verification_status: nil, message_quality_status: nil },
      readiness_known: false,
      unavailable_reason: nil,
      unavailable_reasons: []
    )
  end

  it 'uses per-inbox stored modes before the process-wide allowlist fallback' do
    whatsapp_channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
      phone_number_health: { 'account_mode' => 'LIVE' }
    )
    test_channel = create(
      :channel_whatsapp,
      account: conversation.account,
      provider: 'whatsapp_cloud',
      validate_provider_config: false,
      sync_templates: false,
      phone_number_health: { 'account_mode' => 'TEST' }
    )
    test_contact = create(:contact, account: conversation.account, phone_number: '+15550000003')
    test_contact_inbox = create(:contact_inbox, inbox: test_channel.inbox, contact: test_contact, source_id: '15550000003')
    test_conversation = create(:conversation, account: conversation.account, inbox: test_channel.inbox, contact_inbox: test_contact_inbox)
    create(:message, :incoming, conversation: test_conversation, account: conversation.account, inbox: test_channel.inbox)
    test_eligibility = described_class.new(test_conversation)

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000009' do
      expect(eligibility.capabilities).to include(
        account_mode: 'production',
        recipient: { test_allowlisted: nil, service_window_open: true }
      )
      expect(eligibility.capabilities.dig(:interactive_types, :button)).to include(available: true)
      expect(test_eligibility.capabilities).to include(
        account_mode: 'test',
        recipient: { test_allowlisted: false, service_window_open: true }
      )
      expect(test_eligibility.capabilities.dig(:interactive_types, :button, :unavailable_reasons))
        .to include('test_recipient_not_allowlisted')
    end
  end

  it 'rejects valid E.164 prefix and suffix near matches without disclosing them' do
    protected_values = '+1555000000,+155500000010'

    with_modified_env described_class::TEST_ALLOWLIST_ENV => protected_values do
      capability = eligibility.capabilities

      expect(capability.dig(:recipient, :test_allowlisted)).to be(false)
      expect(capability.dig(:interactive_types, :button, :unavailable_reasons)).to include('test_recipient_not_allowlisted')
      expect(capability.to_json).not_to include(*protected_values.split(','))
    end
  end

  it 'does not use business verification as a CTA availability gate' do
    whatsapp_channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
      phone_number_health: { 'business_verification_status' => 'not_verified' }
    )
    allow(Whatsapp::InteractiveMessages::Registry).to receive(:implemented?) do |type|
      %w[button cta_url].include?(type)
    end

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect(eligibility.capabilities.dig(:interactive_types, :cta_url)).to include(implemented: true, available: true)
    end
  end

  it 'returns the stable test-recipient restriction for a non-allowlisted recipient' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      expect(eligibility.reason).to eq('test_recipient_not_allowlisted')
      expect { eligibility.ensure_available! }
        .to raise_error(Whatsapp::InteractiveMessages::EligibilityError, 'test_recipient_not_allowlisted')
    end
  end

  it 'returns the stable service-window restriction when the window is closed' do
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect(eligibility.reason).to eq('service_window_closed')
    end
  end

  context 'with a 360dialog inbox' do
    let(:provider) { 'default' }

    it 'reports that the provider is unsupported' do
      with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
        capability = eligibility.capabilities.dig(:interactive_types, :button)

        expect(capability).to include(
          implemented: false,
          available: false,
          unavailable_reason: 'provider_not_supported',
          unavailable_reasons: ['provider_not_supported']
        )
      end
    end
  end
end
