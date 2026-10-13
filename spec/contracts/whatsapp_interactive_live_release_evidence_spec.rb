require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'WhatsApp interactive live release evidence contract' do
  let(:fixture_root) { Rails.root.join('spec/fixtures/whatsapp_interactive_messages') }
  let(:story_21) { JSON.parse(fixture_root.join('live_story_21.json').read) }
  let(:story_22) { JSON.parse(fixture_root.join('live_story_22.json').read) }
  let(:evidence_path) { fixture_root.join('live_story_23.json') }
  let(:evidence) { JSON.parse(evidence_path.read) }
  let(:fingerprint_pattern) { /\Asha256:[0-9a-f]{64}\z/ }
  let(:timestamp_pattern) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ }
  let(:expected_story_22_correlation_boundary) do
    {
      'provider_reply_shape' => 'legacy_button',
      'level' => 'message_and_context_only',
      'structured_reply_persisted' => false,
      'delivery_correlation_present' => false,
      'preset_mapping_present' => false,
      'card_index_present' => false
    }
  end
  let(:expected_environment) do
    {
      'revision' => '15512ea30e2a5070db975e33e50d71b542309c26',
      'composer' => 'authenticated_web',
      'account_mode' => 'test',
      'webhook_verified' => true,
      'messages_subscription_active' => true,
      'recipient_allowlisted' => true,
      'recipient_consent_confirmed' => true
    }
  end
  let(:expected_paths) do
    [
      {
        'name' => 'reply_button',
        'story' => 21,
        'source' => 'live_story_21.json',
        'result' => 'passed',
        'proof_boundary' => 'native rendering and correlated recipient selection'
      },
      {
        'name' => 'native_list',
        'story' => 21,
        'source' => 'live_story_21.json',
        'result' => 'passed',
        'proof_boundary' => 'native rendering, row description, and correlated recipient selection'
      },
      {
        'name' => 'url_carousel',
        'story' => 22,
        'source' => 'live_story_22.json',
        'result' => 'passed',
        'proof_boundary' => 'native rendering and opened destinations without click-webhook evidence'
      },
      {
        'name' => 'quick_reply_carousel',
        'story' => 22,
        'source' => 'live_story_22.json',
        'result' => 'passed',
        'proof_boundary' => 'readable selections with message-and-context-only correlation'
      },
      {
        'name' => 'standalone_cta_url',
        'story' => 23,
        'source' => 'live_story_23.json',
        'result' => 'passed',
        'proof_boundary' => 'native rendering and opened destination without click-webhook evidence'
      }
    ]
  end
  let(:exact_keys) do
    {
      [] => %w[coverage environment limitations observed_at release scenario schema_version story],
      %w[environment] => %w[
        account_mode composer messages_subscription_active recipient_allowlisted recipient_consent_confirmed revision
        webhook_verified
      ],
      %w[scenario] => %w[standalone_cta_url],
      %w[scenario standalone_cta_url] => %w[outbound recipient_observation result],
      %w[scenario standalone_cta_url outbound] => %w[
        body button_label created_at delivery_fingerprint destination provider_message_fingerprint status
      ],
      %w[scenario standalone_cta_url recipient_observation] => %w[
        button_visible content_visible destination_opened observed_body observed_button_label opened_destination rendering
        url_click_webhook_claimed
      ],
      %w[release] => %w[paths result],
      %w[limitations] => %w[
        account_mode mobile_completion_claimed production_readiness_claimed promotion_state_claimed test_only
        url_click_analytics_claimed
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

      paths = record.dig('release', 'paths')
      unless paths.is_a?(Array) && paths.all? { |path| path.is_a?(Hash) && path.keys.sort == %w[name proof_boundary result source story] }
        errors << 'release paths have an unsafe or incomplete shape'
        shape_valid = false
      end
      return errors unless shape_valid

      errors << 'environment does not match the authorized live run' unless record['environment'] == expected_environment
      errors << 'coverage must be limited to the CTA and release scenarios' unless record['coverage'] == %w[SCN-08 SCN-20]
      errors << 'observation timestamp is malformed' unless record['observed_at']&.match?(timestamp_pattern)

      cta = record.dig('scenario', 'standalone_cta_url')
      outbound = cta.fetch('outbound')
      observation = cta.fetch('recipient_observation')
      errors << 'standalone CTA did not pass' unless cta['result'] == 'passed'
      errors << 'standalone CTA was not accepted by the provider' unless %w[delivered read].include?(outbound['status'])
      errors << 'standalone CTA body changed' unless outbound['body'] == 'Story 23 standalone CTA verification'
      errors << 'standalone CTA button changed' unless outbound['button_label'] == 'Open example'
      errors << 'standalone CTA destination changed' unless outbound['destination'] == 'https://example.com/'
      errors << 'standalone CTA timestamp is malformed' unless outbound['created_at']&.match?(timestamp_pattern)
      %w[provider_message_fingerprint delivery_fingerprint].each do |key|
        errors << "#{key} contains a raw identifier" unless outbound[key]&.match?(fingerprint_pattern)
      end

      errors << 'recipient did not observe native CTA rendering' unless observation['rendering'] == 'native_cta_url_button'
      errors << 'recipient did not observe CTA content' unless observation['content_visible'] == true
      errors << 'recipient-observed CTA body changed' unless observation['observed_body'] == outbound['body']
      errors << 'recipient did not observe the CTA button' unless observation['button_visible'] == true
      errors << 'recipient-observed CTA button changed' unless observation['observed_button_label'] == outbound['button_label']
      errors << 'recipient did not open the CTA destination' unless observation['destination_opened'] == true
      errors << 'recipient destination changed' unless observation['opened_destination'] == outbound['destination']
      errors << 'CTA click-webhook evidence was claimed' unless observation['url_click_webhook_claimed'] == false

      errors << 'release evidence did not pass' unless record.dig('release', 'result') == 'passed'
      errors << 'release paths are missing, duplicated, reordered, or overstated' unless paths == expected_paths
      expected_limitations = {
        'test_only' => true,
        'account_mode' => 'test',
        'production_readiness_claimed' => false,
        'mobile_completion_claimed' => false,
        'promotion_state_claimed' => false,
        'url_click_analytics_claimed' => false
      }
      errors << 'release limitations were weakened' unless record['limitations'] == expected_limitations

      errors
    rescue KeyError => e
      ["missing Story 23 evidence: #{e.key}"]
    end
  end

  it 'records the authorized CTA outcome and exact five-path release view' do
    expect(evidence).to include('schema_version' => 1, 'story' => 23)
    expect(validation_errors.call(evidence)).to be_empty
  end

  it 'validates the referenced Story 21 evidence directly', :aggregate_failures do
    expect(story_21).to include(
      'story' => 21,
      'coverage' => %w[SCN-04 SCN-05 SCN-20]
    )
    expect(story_21.fetch('scenarios').keys.sort).to eq(%w[native_list reply_button])
    expect(story_21.fetch('scenarios').values.pluck('result')).to all(eq('passed'))
    expect(story_21.fetch('environment')).to eq(
      'revision' => 'afb29e3b0ff5ec9830994337052227256cd09c07',
      'composer' => 'authenticated_web',
      'account_mode' => 'test',
      'webhook_verified' => true,
      'messages_subscription_active' => true,
      'recipient_allowlisted' => true,
      'recipient_consent_confirmed' => true
    )
    story_21.fetch('scenarios').each_value do |scenario|
      expect(scenario.dig('outbound', 'status')).to be_in(%w[delivered read])
      expect(scenario.fetch('inbound')).to include(
        'context_fingerprint' => scenario.dig('outbound', 'provider_message_fingerprint'),
        'delivery_fingerprint' => scenario.dig('outbound', 'delivery_fingerprint')
      )
    end
    story_21_fingerprints = story_21.to_json.scan(/"[^"]*_fingerprint":"([^"]+)"/).flatten
    expect(story_21_fingerprints.length).to eq(14)
    expect(story_21_fingerprints).to all(match(fingerprint_pattern))
    expect(story_21.dig('scenarios', 'reply_button', 'recipient_observation')).to include(
      'rendering' => 'native_reply_buttons',
      'flattened' => false,
      'selection_performed' => true
    )
    expect(story_21.dig('scenarios', 'native_list', 'recipient_observation')).to include(
      'rendering' => 'native_list_bottom_sheet',
      'flattened' => false,
      'description_visible' => true,
      'selection_performed' => true
    )
  end

  it 'validates the referenced Story 22 evidence directly', :aggregate_failures do
    expect(story_22).to include(
      'story' => 22,
      'coverage' => %w[SCN-06 SCN-07 SCN-13 SCN-20]
    )
    expect(story_22.fetch('scenarios').keys.sort).to eq(%w[quick_reply_carousel url_carousel])
    expect(story_22.fetch('scenarios').values.pluck('result')).to all(eq('passed'))
    expect(story_22.fetch('environment')).to eq(
      'revision' => '1d945ccdc5ea618d77b8dc4b40d7d2c614ebd0f1',
      'composer' => 'authenticated_web',
      'account_mode' => 'test',
      'webhook_verified' => true,
      'messages_subscription_active' => true,
      'recipient_allowlisted' => true,
      'recipient_consent_confirmed' => true
    )
    story_22.fetch('scenarios').each_value do |scenario|
      expect(scenario.dig('outbound', 'status')).to be_in(%w[delivered read])
    end
    story_22_fingerprints = story_22.to_json.scan(/"[^"]*_fingerprint":"([^"]+)"/).flatten
    expect(story_22_fingerprints.length).to eq(12)
    expect(story_22_fingerprints).to all(match(fingerprint_pattern))
    expect(story_22.dig('scenarios', 'url_carousel', 'recipient_observation')).to include(
      'rendering' => 'native_image_carousel',
      'flattened' => false,
      'both_images_visible' => true,
      'actions' => [
        include('destination' => 'https://www.wikipedia.org/', 'opened' => true),
        include('destination' => 'https://www.mozilla.org/', 'opened' => true)
      ]
    )
    expect(story_22.dig('scenarios', 'quick_reply_carousel', 'recipient_observation')).to include(
      'rendering' => 'native_image_carousel',
      'flattened' => false,
      'both_images_visible' => true,
      'button_titles' => ['Select Alpha', 'Choose Beta'],
      'selection_performed' => true,
      'selection_count' => 2
    )
    expect(story_22.dig('scenarios', 'url_carousel', 'recipient_observation', 'url_click_webhook_claimed')).to be(false)
    expect(story_22.dig('scenarios', 'quick_reply_carousel', 'correlation_boundary'))
      .to eq(expected_story_22_correlation_boundary)
    quick_reply = story_22.dig('scenarios', 'quick_reply_carousel')
    expect(quick_reply.fetch('inbound').length).to eq(2)
    expect(quick_reply.fetch('inbound')).to all(include(
                                                  'context_fingerprint' => quick_reply.dig('outbound', 'provider_message_fingerprint'),
                                                  'originating_message_fingerprint' => quick_reply.dig('outbound', 'delivery_fingerprint'),
                                                  'readable_content_persisted' => true
                                                ))
  end

  it 'rejects missing, duplicated, failed, or overstated release paths' do
    missing_path = evidence.deep_dup.tap { |record| record.dig('release', 'paths').pop }
    duplicated_path = evidence.deep_dup.tap do |record|
      record.dig('release', 'paths')[-1] = record.dig('release', 'paths').first.deep_dup
    end
    failed_cta = evidence.deep_dup.tap { |record| record.dig('scenario', 'standalone_cta_url')['result'] = 'failed' }
    overstated_boundary = evidence.deep_dup.tap do |record|
      record.dig('release', 'paths', 3)['proof_boundary'] = 'card-level preset and delivery correlation'
    end

    [missing_path, duplicated_path, overstated_boundary].each do |record|
      expect(validation_errors.call(record)).to include('release paths are missing, duplicated, reordered, or overstated')
    end
    expect(validation_errors.call(failed_cta)).to include('standalone CTA did not pass')
  end

  it 'keeps protected values and unsupported release claims out of committed evidence' do
    serialized = %w[README.md live_story_21.json live_story_22.json live_story_23.json]
                 .map { |file_name| fixture_root.join(file_name).read }
                 .join("\n")
    forbidden_patterns = [
      /\+[1-9][0-9]{7,14}/,
      /\bwamid\./i,
      /WHATSAPP_TEST_RECIPIENT_ALLOWLIST|webhook_verify_token|access[_-]?token/i,
      /business[_ -]?verif/i
    ]
    expect(forbidden_patterns.map { |pattern| serialized.match?(pattern) }).to all(be(false))

    raw_identifier = evidence.deep_dup.tap do |record|
      record.dig('scenario', 'standalone_cta_url', 'outbound')['message_id'] = 'opaque-provider-id'
    end
    click_claim = evidence.deep_dup.tap do |record|
      record.dig('scenario', 'standalone_cta_url', 'recipient_observation')['url_click_webhook_claimed'] = true
    end
    production_claim = evidence.deep_dup.tap { |record| record['limitations']['production_readiness_claimed'] = true }
    mobile_claim = evidence.deep_dup.tap { |record| record['limitations']['mobile_completion_claimed'] = true }
    promotion_claim = evidence.deep_dup.tap { |record| record['limitations']['promotion_state_claimed'] = true }

    expect(validation_errors.call(raw_identifier)).to include('scenario.standalone_cta_url.outbound has unexpected keys')
    expect(validation_errors.call(click_claim)).to include('CTA click-webhook evidence was claimed')
    [production_claim, mobile_claim, promotion_claim].each do |record|
      expect(validation_errors.call(record)).to include('release limitations were weakened')
    end
  end
end
# rubocop:enable RSpec/DescribeClass
