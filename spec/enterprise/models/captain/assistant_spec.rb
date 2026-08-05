require 'rails_helper'

RSpec.describe Captain::Assistant do
  describe 'inactivity policy settings' do
    let(:assistant) { create(:captain_assistant, config: {}) }

    it 'uses safe defaults when settings are unavailable' do
      assistant.account.enable_features('captain_integration_v2')
      assistant.auto_resolve_after = nil

      expect(assistant.inactivity_threshold_minutes).to eq(60)

      assistant.auto_resolve_after = 5
      assistant.send_inactivity_resolution_message = false
      assistant.account.disable_features('captain_integration_v2')

      expect(assistant.inactivity_threshold_minutes).to eq(60)
      expect(assistant.send_inactivity_resolution_message?).to be true
      expect(assistant.follow_up_before_resolving?).to be false
      expect(assistant.follow_up_resolution_threshold_minutes).to eq(60)
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

    it 'reads the saved follow-up policy' do
      assistant.update!(
        config: assistant.config.merge(
          'follow_up_before_resolving' => true,
          'follow_up_resolve_after' => 90
        )
      )

      expect(assistant.follow_up_before_resolving?).to be true
      expect(assistant.follow_up_resolution_threshold_minutes).to eq(90)
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

  describe '#agent_tools' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

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
end
