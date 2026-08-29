require 'rails_helper'

RSpec.describe Captain::Assistant, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'US' }) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }

  describe 'inactive conversation settings' do
    it 'uses safe defaults when settings are unavailable' do
      assistant.account.enable_features('captain_integration_v2')
      assistant.auto_resolve_after = nil

      expect(assistant.inactivity_threshold_minutes).to eq(60)

      assistant.auto_resolve_after = 5
      assistant.send_inactivity_resolution_message = false
      assistant.account.disable_features('captain_integration_v2')

      expect(assistant.inactivity_threshold_minutes).to eq(60)
      expect(assistant.send_inactivity_resolution_message?).to be(true)
    end

    it 'validates the inactivity timer range' do
      assistant.auto_resolve_after = 4

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_after]).to be_present

      assistant.auto_resolve_after = 61.5

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_after]).to be_present
    end

    it 'rounds the inactivity timer to the nearest five minutes' do
      assistant.auto_resolve_after = 61

      assistant.validate

      expect(assistant.auto_resolve_after).to eq(60)

      assistant.auto_resolve_after = 63
      assistant.validate

      expect(assistant.auto_resolve_after).to eq(65)
    end
  end

  describe '#auto_resolve_mode' do
    let(:account) { create(:account, captain_auto_resolve_mode: 'legacy') }

    it 'uses the assistant setting when configured' do
      assistant = create(:captain_assistant, account: account, config: { 'auto_resolve_mode' => 'disabled' })

      expect(assistant.auto_resolve_mode).to eq('disabled')
    end

    it 'falls back to the account setting for assistants that have not been migrated' do
      assistant = create(:captain_assistant, account: account)

      expect(assistant.auto_resolve_mode).to eq('legacy')
    end

    it 'rejects unsupported modes' do
      assistant = build(:captain_assistant, account: account, config: { 'auto_resolve_mode' => 'unsupported' })

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_mode]).to be_present
    end
  end

  describe '#responds_to_audience?' do
    it 'returns true when no audience is configured' do
      expect(assistant.responds_to_audience?(contact, conversation)).to be(true)
    end

    it 'returns true when the contact matches the audience' do
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
      expect(assistant.responds_to_audience?(contact, conversation)).to be(true)
    end

    it 'returns false when the contact does not match the audience' do
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['CA']
                                                       }))
      expect(assistant.responds_to_audience?(contact, conversation)).to be(false)
    end
  end

  describe '#available_now?' do
    let(:inbox) { create(:inbox, account: account) }
    let(:scheduled_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

    it 'is available when the window is blank or always' do
      expect(assistant.available_now?(scheduled_conversation)).to be(true)
      assistant.config['response_window'] = 'always'
      expect(assistant.available_now?(scheduled_conversation)).to be(true)
    end

    it 'is available regardless when the inbox has no business hours configured' do
      inbox.update!(working_hours_enabled: false)
      assistant.config['response_window'] = 'business_hours'
      expect(assistant.available_now?(scheduled_conversation)).to be(true)
    end

    context 'when the inbox has business hours enabled' do
      before { inbox.update!(working_hours_enabled: true) }

      it 'business_hours matches only when the inbox is open' do
        assistant.config['response_window'] = 'business_hours'
        allow(scheduled_conversation.inbox).to receive(:out_of_office?).and_return(false)
        expect(assistant.available_now?(scheduled_conversation)).to be(true)
        allow(scheduled_conversation.inbox).to receive(:out_of_office?).and_return(true)
        expect(assistant.available_now?(scheduled_conversation)).to be(false)
      end

      it 'outside_business_hours matches only when the inbox is closed' do
        assistant.config['response_window'] = 'outside_business_hours'
        allow(scheduled_conversation.inbox).to receive(:out_of_office?).and_return(true)
        expect(assistant.available_now?(scheduled_conversation)).to be(true)
        allow(scheduled_conversation.inbox).to receive(:out_of_office?).and_return(false)
        expect(assistant.available_now?(scheduled_conversation)).to be(false)
      end
    end
  end

  describe 'response_window validation' do
    it 'accepts a blank response_window' do
      assistant.config['response_window'] = nil
      expect(assistant).to be_valid
    end

    it 'accepts the known windows' do
      described_class::RESPONSE_WINDOWS.each do |window|
        assistant.config['response_window'] = window
        expect(assistant).to be_valid
      end
    end

    it 'rejects an unknown window' do
      assistant.config['response_window'] = 'weekends'
      expect(assistant).not_to be_valid
      expect(assistant.errors[:config]).to include('invalid response_window')
    end
  end

  describe 'audience validation' do
    let(:leaf) { { 'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US'] } }

    it 'accepts a blank audience' do
      assistant.config['audience'] = nil
      expect(assistant).to be_valid
    end

    it 'accepts a single leaf' do
      assistant.config['audience'] = leaf
      expect(assistant).to be_valid
    end

    it 'accepts symbol keys' do
      assistant.config['audience'] = { attribute_key: 'country_code', filter_operator: 'equal_to', values: ['US'] }
      expect(assistant).to be_valid
    end

    it 'accepts a well-formed nested tree' do
      assistant.config['audience'] = {
        'operator' => 'and',
        'conditions' => [
          { 'operator' => 'or', 'conditions' => [leaf] },
          leaf
        ]
      }
      expect(assistant).to be_valid
    end

    it 'rejects a node that is not a hash' do
      assistant.config['audience'] = ['not-a-node']
      expect(assistant).not_to be_valid
      expect(assistant.errors[:config]).to include('audience must be a valid condition tree')
    end

    it 'rejects an unknown operator' do
      assistant.config['audience'] = leaf.merge('filter_operator' => 'bogus')
      expect(assistant).not_to be_valid
    end

    it 'rejects an operator unsupported by a standard attribute' do
      assistant.config['audience'] = leaf.merge('attribute_key' => 'blocked', 'filter_operator' => 'is_not_present', 'values' => [])
      expect(assistant).not_to be_valid
    end

    it 'rejects a leaf missing attribute_key' do
      assistant.config['audience'] = { 'filter_operator' => 'equal_to', 'values' => ['US'] }
      expect(assistant).not_to be_valid
    end

    it 'rejects conversation language conditions' do
      assistant.config['audience'] = {
        'attribute_key' => 'conversation_language', 'filter_operator' => 'equal_to', 'values' => ['en']
      }

      expect(assistant).not_to be_valid
    end

    it 'rejects an unknown custom attribute' do
      assistant.config['audience'] = {
        'attribute_key' => 'missing_attribute', 'filter_operator' => 'not_equal_to', 'values' => ['known']
      }

      expect(assistant).not_to be_valid
    end

    it 'accepts an operator supported by a defined custom attribute' do
      create(:custom_attribute_definition, account: account, attribute_model: :contact_attribute,
                                           attribute_display_type: :date, attribute_key: 'signed_up_on')
      assistant.config['audience'] = {
        'attribute_key' => 'signed_up_on', 'filter_operator' => 'is_present', 'values' => []
      }

      expect(assistant).to be_valid
    end

    it 'rejects a group without conditions' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => [] }
      expect(assistant).not_to be_valid
    end

    it 'rejects an unknown group operator' do
      assistant.config['audience'] = { 'operator' => 'xor', 'conditions' => [leaf] }
      expect(assistant).not_to be_valid
    end

    it 'rejects a value-taking leaf without values' do
      assistant.config['audience'] = { 'attribute_key' => 'email', 'filter_operator' => 'contains' }
      expect(assistant).not_to be_valid
    end

    it 'rejects a valueless operator when the attribute does not support it' do
      assistant.config['audience'] = { 'attribute_key' => 'email', 'filter_operator' => 'is_present' }
      expect(assistant).not_to be_valid
    end

    it 'rejects conditions that is not an array' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => leaf }
      expect(assistant).not_to be_valid
    end

    it 'rejects a group containing an invalid child' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => [leaf, { 'attribute_key' => '' }] }
      expect(assistant).not_to be_valid
    end

    it 'rejects nesting deeper than one level' do
      assistant.config['audience'] = {
        'operator' => 'and',
        'conditions' => [
          { 'operator' => 'or', 'conditions' => [
            { 'operator' => 'and', 'conditions' => [leaf] }
          ] }
        ]
      }
      expect(assistant).not_to be_valid
    end
  end

  describe '#agent_tools' do
    it 'includes enabled custom tools from the assistant account' do
      custom_tool = create(:captain_custom_tool, account: account)

      tools = assistant.send(:agent_tools)

      expect(tools.map(&:name)).to include(custom_tool.slug)
      expect(tools.find { |tool| tool.name == custom_tool.slug }).to be_a(Captain::Tools::HttpTool)
    end

    it 'excludes disabled custom tools' do
      custom_tool = create(:captain_custom_tool, :disabled, account: account)

      tools = assistant.send(:agent_tools)

      expect(tools.map(&:name)).not_to include(custom_tool.slug)
    end

    it 'excludes custom tools from other accounts' do
      custom_tool = create(:captain_custom_tool)

      tools = assistant.send(:agent_tools)

      expect(tools.map(&:name)).not_to include(custom_tool.slug)
    end

    it 'keeps the built-in FAQ lookup and handoff tools' do
      tools = assistant.send(:agent_tools)

      expect(tools).to include(
        an_instance_of(Captain::Tools::FaqLookupTool),
        an_instance_of(Captain::Tools::HandoffTool)
      )
    end
  end

  describe '#available_tool_ids' do
    it 'excludes disabled custom tools' do
      enabled_tool = create(:captain_custom_tool, account: account)
      disabled_tool = create(:captain_custom_tool, :disabled, account: account)

      expect(assistant.available_tool_ids).to include(enabled_tool.slug)
      expect(assistant.available_tool_ids).not_to include(disabled_tool.slug)
    end
  end

  describe '#known_tool_ids' do
    it 'includes disabled custom tools as valid references' do
      disabled_tool = create(:captain_custom_tool, :disabled, account: account)

      expect(assistant.known_tool_ids).to include(disabled_tool.slug)
    end
  end

  describe '#agent_instructions' do
    it 'keeps the Assistant human handoff prompt unchanged' do
      instructions = assistant.agent_instructions

      expect(instructions).to include('# Human Handoff Protocol', 'captain--tools--handoff')
      expect(instructions).not_to include('You are drafting a reply for a support agent to review.')
    end

    it 'renders the separate Copilot reply suggestion prompt when requested' do
      assistant.update!(
        response_guidelines: ['Include the raw guide URL https://yc.ms/eglb1H.'],
        guardrails: ['Never add citation numbers or footnotes.']
      )
      scenario = create(:captain_scenario, assistant: assistant, account: account, title: 'Refund workflow')

      instructions = assistant.agent_instructions(nil, prompt_template: 'copilot_reply_suggestion')

      expect(instructions).to include(
        'You are drafting a reply for a support agent to review.',
        'Include the raw guide URL https://yc.ms/eglb1H.',
        'Never add citation numbers or footnotes.'
      )
      expect(instructions).not_to include('# Human Handoff Protocol', scenario.title, "handoff_to_#{scenario.handoff_key}")
    end
  end
end
