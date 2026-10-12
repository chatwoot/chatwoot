class Whatsapp::InteractiveMessages::Eligibility
  TEST_ALLOWLIST_ENV = 'WHATSAPP_TEST_RECIPIENT_ALLOWLIST'.freeze
  E164_PATTERN = /\A\+[1-9]\d{1,14}\z/
  TYPE_FEATURES = {
    'button' => 'whatsapp_interactive_button',
    'list' => 'whatsapp_interactive_list',
    'carousel' => 'whatsapp_interactive_carousel',
    'cta_url' => 'whatsapp_interactive_cta_url'
  }.freeze
  READINESS_FACT_SOURCES = {
    waba_review_status: 'waba_review_status',
    business_verification_status: 'business_verification_status',
    production_phone_onboarded: 'production_phone_onboarded',
    app_publication_status: 'app_publication_status',
    billing_configured: 'billing_configured',
    message_quality_status: 'message_quality_status',
    product_enrollment_status: 'product_enrollment_status',
    quality_rating: 'quality_rating',
    phone_number_status: 'status',
    code_verification_status: 'code_verification_status',
    catalog_linked: 'catalog_linked',
    calling_enabled: 'calling_enabled',
    direct_send_enrollment_status: 'direct_send_enrollment_status',
    address_market_eligible: 'address_market_eligible',
    payment_market_eligible: 'payment_market_eligible',
    payment_transaction_integration_configured: 'payment_transaction_integration_configured',
    order_market_eligible: 'order_market_eligible',
    order_transaction_integration_configured: 'order_transaction_integration_configured'
  }.freeze

  def initialize(conversation)
    @conversation = conversation
  end

  def capabilities
    {
      schema_version: Whatsapp::InteractiveMessages::Registry::SCHEMA_VERSION,
      account_mode: account_mode,
      **readiness_facts,
      recipient: {
        test_allowlisted: test_mode? ? test_recipient_allowlisted? : nil,
        service_window_open: @conversation.can_reply?
      },
      send_lanes: send_lanes,
      interactive_types: interactive_types,
      excluded_capabilities: excluded_capabilities
    }
  end

  def ensure_available!(type = 'button')
    unavailable_reason = reason(type)
    raise Whatsapp::InteractiveMessages::EligibilityError, unavailable_reason if unavailable_reason
  end

  def reason(type = 'button') = reasons(type).first

  def reasons(type = 'button')
    type = type.to_s
    return ['provider_not_supported'] unless whatsapp_cloud?

    reasons = []
    reasons << 'unsupported_by_linoo_version' unless Whatsapp::InteractiveMessages::Registry.implemented?(type)
    reasons << 'temporarily_disabled' unless type_enabled?(type)
    reasons << 'service_window_closed' unless @conversation.can_reply?
    reasons << 'test_recipient_not_allowlisted' if test_mode? && !test_recipient_allowlisted?
    reasons
  end

  private

  def whatsapp_cloud?
    channel = @conversation.inbox&.channel
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def type_capability(type)
    unavailable_reasons = reasons(type)
    {
      implemented: whatsapp_cloud? && Whatsapp::InteractiveMessages::Registry.implemented?(type),
      enabled: type_enabled?(type),
      available: unavailable_reasons.empty?,
      unavailable_reason: unavailable_reasons.first,
      unavailable_reasons: unavailable_reasons,
      limits: Whatsapp::InteractiveMessages::Registry.limits_for(type)
    }.compact
  end

  def interactive_types
    TYPE_FEATURES.each_key.to_h { |type| [type.to_sym, type_capability(type)] }.merge(
      location_request_message: existing_location_capability
    )
  end

  def existing_location_capability
    unavailable_reasons = shared_context_reasons
    {
      implemented: whatsapp_cloud?,
      existing: true,
      available: unavailable_reasons.empty?,
      unavailable_reason: unavailable_reasons.first,
      unavailable_reasons: unavailable_reasons
    }.compact
  end

  def type_enabled?(type)
    feature = TYPE_FEATURES[type]
    feature.present? && @conversation.account.feature_enabled?(feature)
  end

  def readiness_facts
    READINESS_FACT_SOURCES.transform_values { |source| health_facts[source] }
  end

  def excluded_capabilities
    {
      flow: exclusion(%w[business_verification_status message_quality_status], flow_exclusion_reasons),
      catalog: exclusion(%w[catalog_linked], reason_if(readiness_facts[:catalog_linked] == false, 'catalog_not_linked')),
      calling: exclusion(%w[calling_enabled], reason_if(readiness_facts[:calling_enabled] == false, 'calling_not_enabled')),
      direct_send: exclusion(
        %w[direct_send_enrollment_status],
        reason_if(readiness_facts[:direct_send_enrollment_status] == 'not_enrolled', 'not_enrolled')
      ),
      address: exclusion(%w[address_market_eligible], reason_if(readiness_facts[:address_market_eligible] == false, 'market_ineligible')),
      payment: exclusion(
        %w[payment_market_eligible payment_transaction_integration_configured],
        commerce_exclusion_reasons(:payment)
      ),
      order: exclusion(
        %w[order_market_eligible order_transaction_integration_configured],
        commerce_exclusion_reasons(:order)
      )
    }
  end

  def exclusion(fact_names, unavailable_reasons)
    facts = readiness_facts.slice(*fact_names.map(&:to_sym))
    {
      readiness: facts,
      readiness_known: facts.values.none?(&:nil?),
      unavailable_reason: unavailable_reasons.first,
      unavailable_reasons: unavailable_reasons
    }
  end

  def flow_exclusion_reasons
    reason_if(readiness_facts[:business_verification_status] == 'not_verified', 'business_not_verified') +
      reason_if(readiness_facts[:message_quality_status] == 'insufficient', 'message_quality_insufficient')
  end

  def commerce_exclusion_reasons(capability)
    reason_if(readiness_facts["#{capability}_market_eligible".to_sym] == false, 'market_ineligible') +
      reason_if(readiness_facts["#{capability}_transaction_integration_configured".to_sym] == false,
                'transaction_integration_missing')
  end

  def reason_if(condition, reason) = condition ? [reason] : []

  def health_facts = @conversation.inbox&.channel&.phone_number_health.to_h.stringify_keys

  def account_mode
    stored_mode = health_facts['account_mode']&.downcase
    return 'test' if stored_mode == 'test'
    return 'production' if stored_mode == 'live'
    return 'test' if test_mode?

    'production'
  end

  def send_lanes
    lanes = ['template']
    lanes.unshift('service') if @conversation.can_reply?
    lanes
  end

  def shared_context_reasons
    return ['provider_not_supported'] unless whatsapp_cloud?

    shared_reasons = []
    shared_reasons << 'service_window_closed' unless @conversation.can_reply?
    shared_reasons
  end

  def test_mode?
    stored_mode = health_facts['account_mode']&.downcase
    return stored_mode == 'test' if %w[test live].include?(stored_mode)

    ENV[TEST_ALLOWLIST_ENV].present?
  end

  def test_recipient_allowlisted? = allowlist.include?(normalized_recipient)

  def allowlist
    ENV.fetch(TEST_ALLOWLIST_ENV, '').split(',').filter_map do |entry|
      candidate = entry.strip
      candidate if candidate.match?(E164_PATTERN)
    end
  end

  def normalized_recipient
    recipient = @conversation.contact_inbox&.source_id.to_s.delete_prefix('whatsapp:')
    recipient = "+#{recipient}" if recipient.match?(/\A[1-9]\d{1,14}\z/)
    recipient if recipient.match?(E164_PATTERN)
  end
end
