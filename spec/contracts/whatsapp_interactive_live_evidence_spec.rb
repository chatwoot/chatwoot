require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'WhatsApp interactive Story 21 live evidence contract' do
  let(:evidence_path) do
    Rails.root.join('spec/fixtures/whatsapp_interactive_messages/live_story_21.json')
  end
  let(:evidence) { JSON.parse(evidence_path.read) }
  let(:fingerprint_pattern) { /\Asha256:[0-9a-f]{64}\z/ }
  let(:timestamp_pattern) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ }
  let(:accepted_outbound_statuses) { %w[delivered read] }
  let(:expected_environment) do
    {
      'revision' => 'afb29e3b0ff5ec9830994337052227256cd09c07',
      'composer' => 'authenticated_web',
      'account_mode' => 'test',
      'webhook_verified' => true,
      'messages_subscription_active' => true,
      'recipient_allowlisted' => true,
      'recipient_consent_confirmed' => true
    }
  end
  let(:expected_implementation_follow_up) do
    {
      'source' => 'recipient_observation',
      'defect' => 'interactive setup exceeded the normal-zoom viewport without an internal scroll region',
      'status' => 'fixed_and_regression_tested',
      'viewport_constrained' => true,
      'internal_scroll_region' => true,
      'send_controls_remain_outside_scroll_region' => true,
      'browser_normal_zoom_verified' => true,
      'internal_overflow_observed' => true,
      'send_controls_within_viewport' => true
    }
  end
  let(:exact_keys) do
    {
      [] => %w[coverage environment implementation_follow_up observed_at scenarios schema_version story],
      %w[environment] => %w[
        account_mode composer messages_subscription_active recipient_allowlisted
        recipient_consent_confirmed revision webhook_verified
      ],
      %w[implementation_follow_up] => %w[
        browser_normal_zoom_verified defect internal_overflow_observed internal_scroll_region
        send_controls_remain_outside_scroll_region send_controls_within_viewport source status viewport_constrained
      ],
      %w[scenarios] => %w[native_list reply_button],
      %w[scenarios reply_button] => %w[inbound outbound recipient_observation result],
      %w[scenarios reply_button outbound] => %w[
        body created_at delivery_fingerprint preset_fingerprint preset_option_fingerprint
        provider_message_fingerprint selected_button_title status
      ],
      %w[scenarios reply_button recipient_observation] => %w[flattened rendering selection_performed],
      %w[scenarios reply_button inbound] => %w[
        context_fingerprint created_at delivery_fingerprint originating_snapshot_found
        preset_option_fingerprint readable_content_persisted reply_type title
      ],
      %w[scenarios native_list] => %w[inbound outbound recipient_observation result],
      %w[scenarios native_list outbound] => %w[
        body created_at delivery_fingerprint opening_button preset_fingerprint preset_option_fingerprint
        provider_message_fingerprint row_description row_title status
      ],
      %w[scenarios native_list recipient_observation] => %w[
        description_visible flattened rendering selection_performed
      ],
      %w[scenarios native_list inbound] => %w[
        context_fingerprint created_at delivery_fingerprint description description_persisted
        originating_snapshot_found preset_option_fingerprint readable_content_persisted reply_type title
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
      errors << 'Story 21 scenarios must cover reply buttons and native lists' unless scenarios.keys.sort == %w[native_list reply_button]
      errors << 'coverage must be limited to Story 21 scenarios' unless record['coverage'] == %w[SCN-04 SCN-05 SCN-20]
      errors << 'environment does not match the authorized live run' unless record['environment'] == expected_environment
      unless record['implementation_follow_up'] == expected_implementation_follow_up
        errors << 'implementation follow-up does not match the verified observation'
      end
      next errors unless shape_valid

      scenarios.each do |name, scenario|
        outbound = scenario.fetch('outbound')
        inbound = scenario.fetch('inbound')
        observation = scenario.fetch('recipient_observation')
        errors << "#{name} did not pass" unless scenario['result'] == 'passed'
        errors << "#{name} outbound was not accepted and rendered" unless accepted_outbound_statuses.include?(outbound['status'])
        errors << "#{name} recipient selection is missing" unless observation['selection_performed'] == true
        errors << "#{name} was flattened" unless observation['flattened'] == false
        errors << "#{name} originating snapshot is missing" unless inbound['originating_snapshot_found'] == true
        errors << "#{name} readable content is missing" unless inbound['readable_content_persisted'] == true
        errors << "#{name} delivery identity is broken" unless inbound['delivery_fingerprint'] == outbound['delivery_fingerprint']
        errors << "#{name} provider context is broken" unless inbound['context_fingerprint'] == outbound['provider_message_fingerprint']
        errors << "#{name} preset option mapping is broken" unless inbound['preset_option_fingerprint'] == outbound['preset_option_fingerprint']

        fingerprint_keys = outbound.keys.grep(/_fingerprint\z/) + inbound.keys.grep(/_fingerprint\z/)
        errors << "#{name} fingerprint fields are incomplete" unless fingerprint_keys.sort == %w[
          context_fingerprint delivery_fingerprint delivery_fingerprint preset_fingerprint
          preset_option_fingerprint preset_option_fingerprint provider_message_fingerprint
        ]
        (outbound.values_at(*outbound.keys.grep(/_fingerprint\z/)) + inbound.values_at(*inbound.keys.grep(/_fingerprint\z/))).each do |fingerprint|
          errors << "#{name} contains a raw identifier" unless fingerprint&.match?(fingerprint_pattern)
        end
      end

      button = scenarios.fetch('reply_button')
      button_outbound = button.fetch('outbound')
      button_inbound = button.fetch('inbound')
      button_observation = button.fetch('recipient_observation')
      errors << 'reply button did not use native rendering' unless button_observation['rendering'] == 'native_reply_buttons'
      errors << 'reply button inbound type changed' unless button_inbound['reply_type'] == 'button_reply'
      errors << 'reply button title changed' unless button_inbound['title'] == button_outbound['selected_button_title']
      errors << 'reply button body changed' unless button_outbound['body'] == 'Story 21 reply-button verification'
      errors << 'reply button option changed' unless button_outbound['selected_button_title'] == 'Confirm'

      list = scenarios.fetch('native_list')
      list_outbound = list.fetch('outbound')
      list_inbound = list.fetch('inbound')
      list_observation = list.fetch('recipient_observation')
      errors << 'native list did not use the native bottom-sheet experience' unless list_observation['rendering'] == 'native_list_bottom_sheet'
      errors << 'native list description was not observed' unless list_observation['description_visible'] == true
      errors << 'native list description was not persisted' unless list_inbound['description_persisted'] == true
      errors << 'native list title changed' unless list_inbound['title'] == list_outbound['row_title']
      errors << 'native list description changed' unless list_inbound['description'] == list_outbound['row_description']
      errors << 'native list inbound type changed' unless list_inbound['reply_type'] == 'list_reply'
      errors << 'native list body changed' unless list_outbound['body'] == 'Story 21 native-list verification'
      errors << 'native list opening button changed' unless list_outbound['opening_button'] == 'View options'
      errors << 'native list row title changed' unless list_outbound['row_title'] == 'Native list confirmed'
      errors << 'native list row description changed' unless list_outbound['row_description'] == 'Recipient observed the native list'

      %w[provider_message_fingerprint delivery_fingerprint preset_fingerprint preset_option_fingerprint].each do |key|
        values = scenarios.values.map { |scenario| scenario.dig('outbound', key) }
        errors << "Story 21 #{key} values do not identify separate live sends" unless values.uniq.length == scenarios.length
      end

      errors << 'observation timestamp is malformed' unless record['observed_at']&.match?(timestamp_pattern)
      scenarios.each_value do |scenario|
        %w[outbound inbound].each do |direction|
          errors << "#{direction} timestamp is malformed" unless scenario.dig(direction, 'created_at')&.match?(timestamp_pattern)
        end
      end

      errors
    rescue KeyError => e
      ["missing Story 21 evidence: #{e.key}"]
    end
  end

  it 'records the authorized environment and both live Story 21 paths' do
    expect(evidence).to include(
      'schema_version' => 1,
      'story' => 21,
      'coverage' => %w[SCN-04 SCN-05 SCN-20]
    )
    expect(evidence.fetch('environment')).to eq(expected_environment)
    expect(evidence.fetch('implementation_follow_up')).to eq(expected_implementation_follow_up)
    expect(validation_errors.call(evidence)).to be_empty
  end

  it 'rejects missing paths, failed states, broken correlation, or flattened list evidence' do
    missing_path = evidence.deep_dup.tap { |record| record.fetch('scenarios').delete('reply_button') }
    failed_state = evidence.deep_dup.tap { |record| record.dig('scenarios', 'reply_button')['result'] = 'failed' }
    broken_correlation = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'native_list', 'inbound')['context_fingerprint'] = "sha256:#{'0' * 64}"
    end
    flattened_list = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'native_list', 'recipient_observation')['flattened'] = true
    end
    duplicate_live_identities = evidence.deep_dup.tap do |record|
      button = record.dig('scenarios', 'reply_button')
      list = record.dig('scenarios', 'native_list')
      %w[provider_message_fingerprint delivery_fingerprint preset_fingerprint preset_option_fingerprint].each do |key|
        list['outbound'][key] = button.dig('outbound', key)
      end
      list['inbound']['context_fingerprint'] = button.dig('outbound', 'provider_message_fingerprint')
      list['inbound']['delivery_fingerprint'] = button.dig('outbound', 'delivery_fingerprint')
      list['inbound']['preset_option_fingerprint'] = button.dig('outbound', 'preset_option_fingerprint')
    end

    expect(validation_errors.call(missing_path)).to include('Story 21 scenarios must cover reply buttons and native lists')
    expect(validation_errors.call(failed_state)).to include('reply_button did not pass')
    expect(validation_errors.call(broken_correlation)).to include('native_list provider context is broken')
    expect(validation_errors.call(flattened_list)).to include('native_list was flattened')
    %w[provider_message_fingerprint delivery_fingerprint preset_fingerprint preset_option_fingerprint].each do |key|
      expect(validation_errors.call(duplicate_live_identities)).to include(
        "Story 21 #{key} values do not identify separate live sends"
      )
    end
  end

  it 'enforces the exact safe shape instead of permitting recipients, credentials, or raw identifiers' do
    serialized = evidence_path.read
    recipient = evidence.deep_dup.tap { |record| record['recipient'] = '15551234567' }
    credential = evidence.deep_dup.tap { |record| record['credential'] = 'secret' }
    raw_identifier = evidence.deep_dup.tap do |record|
      record.dig('scenarios', 'reply_button', 'outbound')['message_id'] = 'opaque-provider-id'
    end
    secret_in_allowed_field = evidence.deep_dup.tap do |record|
      record.fetch('implementation_follow_up')['defect'] = 'opaque-access-token'
    end

    expect(serialized).not_to match(/\+[1-9][0-9]{7,14}/)
    expect(serialized).not_to match(/\bwamid\./i)
    expect(serialized).not_to match(/:\s*"(?:reply|row)_[0-9a-z_-]+"/i)
    expect(serialized).not_to match(/WHATSAPP_TEST_RECIPIENT_ALLOWLIST|webhook_verify_token|access[_-]?token/i)
    expect(
      [recipient, credential, raw_identifier, secret_in_allowed_field].map { |record| validation_errors.call(record) }
    ).to eq([
              ['root has unexpected keys'],
              ['root has unexpected keys'],
              ['scenarios.reply_button.outbound has unexpected keys'],
              ['implementation follow-up does not match the verified observation']
            ])
    expect(validation_errors.call(evidence)).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
