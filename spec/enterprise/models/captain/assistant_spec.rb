require 'rails_helper'

RSpec.describe Captain::Assistant do
  describe 'inactive conversation settings' do
    let(:assistant) { build(:captain_assistant, config: {}) }

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
