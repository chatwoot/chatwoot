require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'WhatsApp interactive Story 22 live carousel evidence contract' do
  let(:evidence_path) do
    Rails.root.join('spec/fixtures/whatsapp_interactive_messages/live_story_22.json')
  end
  let(:evidence) { JSON.parse(evidence_path.read) }
  let(:fingerprint_pattern) { /\Asha256:[0-9a-f]{64}\z/ }
  let(:timestamp_pattern) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ }
  let(:accepted_outbound_statuses) { %w[delivered read] }
  let(:expected_environment) do
    {
      'revision' => '1d945ccdc5ea618d77b8dc4b40d7d2c614ebd0f1',
      'composer' => 'authenticated_web',
      'account_mode' => 'test',
      'webhook_verified' => true,
      'messages_subscription_active' => true,
      'recipient_allowlisted' => true,
      'recipient_consent_confirmed' => true
    }
  end
  let(:expected_correlation_boundary) do
    {
      'provider_reply_shape' => 'legacy_button',
      'level' => 'message_and_context_only',
      'structured_reply_persisted' => false,
      'delivery_correlation_present' => false,
      'preset_mapping_present' => false,
      'card_index_present' => false
    }
  end
  let(:exact_keys) do
    {
      [] => %w[coverage environment observed_at scenarios schema_version story],
      %w[environment] => %w[
        account_mode composer messages_subscription_active recipient_allowlisted
        recipient_consent_confirmed revision webhook_verified
      ],
      %w[scenarios] => %w[quick_reply_carousel url_carousel],
      %w[scenarios url_carousel] => %w[outbound recipient_observation result],
      %w[scenarios url_carousel outbound] => %w[
        body card_count created_at delivery_fingerprint provider_message_fingerprint status
      ],
      %w[scenarios url_carousel recipient_observation] => %w[
        actions both_images_visible card_count flattened rendering url_click_webhook_claimed
      ],
      %w[scenarios quick_reply_carousel] => %w[
        correlation_boundary inbound outbound recipient_observation result
      ],
      %w[scenarios quick_reply_carousel outbound] => %w[
        body card_count created_at delivery_fingerprint options provider_message_fingerprint status
      ],
      %w[scenarios quick_reply_carousel recipient_observation] => %w[
        additional_selection_observed both_images_visible button_titles card_count flattened rendering
        selection_count selection_performed
      ],
      %w[scenarios quick_reply_carousel correlation_boundary] => %w[
        card_index_present delivery_correlation_present level preset_mapping_present
        provider_reply_shape structured_reply_persisted
      ]
    }
  end
  let(:validation_errors) do
    lambda do |record|
      errors = []
      shape_valid = true
      exact_keys.each do |path, keys|
        value = path.empty? ? record : record.dig(*path)
        next if value.is_a?(Hash) && value.keys.sort == keys.sort

        errors << "#{path.join('.').presence || 'root'} has unexpected keys"
        shape_valid = false
      end

      scenarios = record.fetch('scenarios')
      errors << 'Story 22 scenarios must cover both carousel modes' unless scenarios.keys.sort == %w[quick_reply_carousel url_carousel]
      errors << 'coverage must be limited to Story 22 scenarios' unless record['coverage'] == %w[SCN-06 SCN-07 SCN-13 SCN-20]
      errors << 'environment does not match the authorized live run' unless record['environment'] == expected_environment
      next errors unless shape_valid

      scenarios.each do |name, scenario|
        outbound = scenario.fetch('outbound')
        observation = scenario.fetch('recipient_observation')
        errors << "#{name} did not pass" unless scenario['result'] == 'passed'
        errors << "#{name} outbound was not accepted and rendered" unless accepted_outbound_statuses.include?(outbound['status'])
        errors << "#{name} card count changed" unless outbound['card_count'] == 2 && observation['card_count'] == 2
        errors << "#{name} did not use native image-carousel rendering" unless observation['rendering'] == 'native_image_carousel'
        errors << "#{name} was flattened" unless observation['flattened'] == false
        errors << "#{name} images were not both observed" unless observation['both_images_visible'] == true
      end

      url = scenarios.fetch('url_carousel')
      url_outbound = url.fetch('outbound')
      url_observation = url.fetch('recipient_observation')
      expected_actions = [
        { 'title' => 'Open Wikipedia', 'destination' => 'https://www.wikipedia.org/', 'opened' => true },
        { 'title' => 'Open Mozilla', 'destination' => 'https://www.mozilla.org/', 'opened' => true }
      ]
      errors << 'URL carousel body changed' unless url_outbound['body'] == 'Story 22 URL carousel verification'
      errors << 'URL destinations were not both observed' unless url_observation['actions'] == expected_actions
      errors << 'URL click webhook evidence was claimed' unless url_observation['url_click_webhook_claimed'] == false

      quick = scenarios.fetch('quick_reply_carousel')
      quick_outbound = quick.fetch('outbound')
      quick_observation = quick.fetch('recipient_observation')
      boundary = quick.fetch('correlation_boundary')
      inbound = quick.fetch('inbound')
      errors << 'quick-reply carousel body changed' unless quick_outbound['body'] == 'Story 22 quick-reply carousel verification'
      errors << 'quick-reply buttons changed' unless quick_observation['button_titles'] == ['Select Alpha', 'Choose Beta']
      errors << 'quick-reply selection was not observed' unless quick_observation['selection_performed'] == true
      unless quick_observation['selection_count'] == 2 && quick_observation['additional_selection_observed'] == true
        errors << 'additional live selection was not disclosed'
      end
      errors << 'actual correlation boundary was overstated' unless boundary == expected_correlation_boundary
      errors << 'live inbound selection count changed' unless inbound.length == 2

      expected_option_keys = %w[card_index delivery_fingerprint preset_mapping_present title]
      options = quick_outbound.fetch('options')
      errors << 'outbound option count changed' unless options.length == 2
      options.each_with_index do |option, index|
        errors << "quick option #{index} has unexpected keys" unless option.keys.sort == expected_option_keys.sort
        errors << "quick option #{index} card identity changed" unless option['card_index'] == index
        errors << "quick option #{index} invented preset mapping" unless option['preset_mapping_present'] == false
      end
      errors << 'quick option titles changed' unless options.pluck('title') == ['Select Alpha', 'Choose Beta']
      errors << 'quick option delivery identities are not distinct' unless options.pluck('delivery_fingerprint').uniq.length == 2

      expected_inbound_keys = %w[
        context_fingerprint created_at inbound_message_fingerprint originating_message_fingerprint
        readable_content_persisted title
      ]
      inbound.each_with_index do |reply, index|
        errors << "inbound reply #{index} has unexpected keys" unless reply.keys.sort == expected_inbound_keys.sort
        errors << "inbound reply #{index} readable content is missing" unless reply['readable_content_persisted'] == true
        unless reply['context_fingerprint'] == quick_outbound['provider_message_fingerprint']
          errors << "inbound reply #{index} provider context is broken"
        end
        unless reply['originating_message_fingerprint'] == quick_outbound['delivery_fingerprint']
          errors << "inbound reply #{index} originating message is broken"
        end
      end
      errors << 'inbound reply titles changed' unless inbound.pluck('title') == ['Select Alpha', 'Choose Beta']
      errors << 'inbound message identities are not distinct' unless inbound.pluck('inbound_message_fingerprint').uniq.length == 2

      outbound_provider_fingerprints = scenarios.values.map { |scenario| scenario.dig('outbound', 'provider_message_fingerprint') }
      outbound_delivery_fingerprints = scenarios.values.map { |scenario| scenario.dig('outbound', 'delivery_fingerprint') }
      errors << 'Story 22 provider identities do not identify separate sends' unless outbound_provider_fingerprints.uniq.length == 2
      errors << 'Story 22 message identities do not identify separate sends' unless outbound_delivery_fingerprints.uniq.length == 2

      fingerprint_values = record.to_json.scan(/"[^"]*_fingerprint":"([^"]+)"/).flatten
      errors << 'fingerprint fields are incomplete' unless fingerprint_values.length == 12
      errors << 'evidence contains a raw identifier' unless fingerprint_values.all? { |value| value.match?(fingerprint_pattern) }
      errors << 'observation timestamp is malformed' unless record['observed_at']&.match?(timestamp_pattern)
      errors << 'URL outbound timestamp is malformed' unless url_outbound['created_at']&.match?(timestamp_pattern)
      errors << 'quick outbound timestamp is malformed' unless quick_outbound['created_at']&.match?(timestamp_pattern)
      inbound.each do |reply|
        errors << 'inbound timestamp is malformed' unless reply['created_at']&.match?(timestamp_pattern)
      end

      errors
    rescue KeyError => e
      ["missing Story 22 evidence: #{e.key}"]
    end
  end

  it 'records the authorized environment and both live Story 22 carousel paths' do
    expect(evidence).to include(
      'schema_version' => 1,
      'story' => 22,
      'coverage' => %w[SCN-06 SCN-07 SCN-13 SCN-20]
    )
    expect(evidence.fetch('environment')).to eq(expected_environment)
    expect(validation_errors.call(evidence)).to be_empty
  end

  it 'rejects missing or failed paths, broken message correlation, invented card evidence, and URL webhook claims' do
    missing_path = evidence.deep_dup.tap { |record| record.fetch('scenarios').delete('url_carousel') }
    failed_state = evidence.deep_dup.tap { |record| record.dig('scenarios', 'quick_reply_carousel')['result'] = 'failed' }
    broken_correlation = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'quick_reply_carousel', 'inbound', 0)['context_fingerprint'] = "sha256:#{'0' * 64}"
    end
    invented_card = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'quick_reply_carousel', 'inbound', 0)['card_index'] = 0
    end
    webhook_claim = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'url_carousel', 'recipient_observation')['url_click_webhook_claimed'] = true
    end

    expect(validation_errors.call(missing_path)).to include('Story 22 scenarios must cover both carousel modes')
    expect(validation_errors.call(failed_state)).to include('quick_reply_carousel did not pass')
    expect(validation_errors.call(broken_correlation)).to include('inbound reply 0 provider context is broken')
    expect(validation_errors.call(invented_card)).to include('inbound reply 0 has unexpected keys')
    expect(validation_errors.call(webhook_claim)).to include('URL click webhook evidence was claimed')
  end

  it 'enforces the exact safe shape instead of permitting recipients, credentials, or raw identifiers' do
    serialized = evidence_path.read
    recipient = evidence.deep_dup.tap { |record| record['recipient'] = '15551234567' }
    credential = evidence.deep_dup.tap { |record| record['credential'] = 'secret' }
    raw_identifier = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'url_carousel', 'outbound')['message_id'] = 'opaque-provider-id'
    end
    overstated_boundary = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'quick_reply_carousel', 'correlation_boundary')['card_index_present'] = true
    end

    forbidden_patterns = [
      /\+[1-9][0-9]{7,14}/,
      /\bwamid\./i,
      /:\s*"(?:reply|row)_[0-9a-z_-]+"/i,
      /WHATSAPP_TEST_RECIPIENT_ALLOWLIST|webhook_verify_token|access[_-]?token/i
    ]
    expect(forbidden_patterns.map { |pattern| serialized.match?(pattern) }).to all(be(false))
    expect([recipient, credential, raw_identifier, overstated_boundary].map { |record| validation_errors.call(record) })
      .to eq([
               ['root has unexpected keys'],
               ['root has unexpected keys'],
               ['scenarios.url_carousel.outbound has unexpected keys'],
               ['actual correlation boundary was overstated']
             ])
    expect(validation_errors.call(evidence)).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
