require 'rails_helper'

RSpec.describe Captain::Scenario, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:instruction) }
    it { is_expected.to validate_presence_of(:assistant_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    describe '.enabled' do
      it 'returns only enabled scenarios' do
        enabled_scenario = create(:captain_scenario, assistant: assistant, account: account, enabled: true)
        disabled_scenario = create(:captain_scenario, assistant: assistant, account: account, enabled: false)

        expect(described_class.enabled.pluck(:id)).to include(enabled_scenario.id)
        expect(described_class.enabled.pluck(:id)).not_to include(disabled_scenario.id)
      end
    end
  end

  describe 'callbacks' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    describe 'before_save :resolve_tool_references' do
      it 'calls resolve_tool_references before saving' do
        scenario = build(:captain_scenario, assistant: assistant, account: account)
        expect(scenario).to receive(:populate_tools)
        scenario.save!
      end
    end
  end

  describe 'tool validation and population' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    before do
      # Mock available tools
      allow(described_class).to receive(:built_in_tool_ids).and_return(%w[
                                                                         add_contact_note add_private_note update_priority
                                                                       ])
    end

    describe 'validate_instruction_tools' do
      it 'is valid with valid tool references' do
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Add Contact Note](tool://add_contact_note) to document')

        expect(scenario).to be_valid
      end

      it 'is invalid with invalid tool references' do
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Invalid Tool](tool://invalid_tool) to process')

        expect(scenario).not_to be_valid
        expect(scenario.errors[:instruction]).to include('contains invalid tools: invalid_tool')
      end

      it 'is invalid with multiple invalid tools' do
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Invalid Tool](tool://invalid_tool) and [@Another Invalid](tool://another_invalid)')

        expect(scenario).not_to be_valid
        expect(scenario.errors[:instruction]).to include('contains invalid tools: invalid_tool, another_invalid')
      end

      it 'is valid with no tool references' do
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Just respond politely to the customer')

        expect(scenario).to be_valid
      end

      it 'is valid with blank instruction' do
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: '')

        # Will be invalid due to presence validation, not tool validation
        expect(scenario).not_to be_valid
        expect(scenario.errors[:instruction]).not_to include(/contains invalid tools/)
      end

      it 'is valid with custom tool references' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Fetch Order](tool://custom_fetch-order) to get order details')

        expect(scenario).to be_valid
      end

      it 'is invalid with custom tool from different account' do
        other_account = create(:account)
        create(:captain_custom_tool, account: other_account, slug: 'custom_fetch-order')
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Fetch Order](tool://custom_fetch-order) to get order details')

        expect(scenario).not_to be_valid
        expect(scenario.errors[:instruction]).to include('contains invalid tools: custom_fetch-order')
      end

      it 'is invalid with disabled custom tool' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order', enabled: false)
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Fetch Order](tool://custom_fetch-order) to get order details')

        expect(scenario).not_to be_valid
        expect(scenario.errors[:instruction]).to include('contains invalid tools: custom_fetch-order')
      end

      it 'is valid with mixed static and custom tool references' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = build(:captain_scenario,
                         assistant: assistant,
                         account: account,
                         instruction: 'Use [@Add Note](tool://add_contact_note) and [@Fetch Order](tool://custom_fetch-order)')

        expect(scenario).to be_valid
      end
    end

    describe 'resolve_tool_references' do
      it 'populates tools array with referenced tool IDs' do
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'First [@Add Contact Note](tool://add_contact_note) then [@Update Priority](tool://update_priority)')

        expect(scenario.tools).to eq(%w[add_contact_note update_priority])
      end

      it 'sets tools to nil when no tools are referenced' do
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Just respond politely to the customer')

        expect(scenario.tools).to be_nil
      end

      it 'handles duplicate tool references' do
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Add Contact Note](tool://add_contact_note) and [@Add Contact Note](tool://add_contact_note) again')

        expect(scenario.tools).to eq(['add_contact_note'])
      end

      it 'updates tools when instruction changes' do
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Add Contact Note](tool://add_contact_note)')

        expect(scenario.tools).to eq(['add_contact_note'])

        scenario.update!(instruction: 'Use [@Update Priority](tool://update_priority) instead')
        expect(scenario.tools).to eq(['update_priority'])
      end
    end
  end

  describe 'custom tool integration' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    before do
      allow(described_class).to receive(:built_in_tool_ids).and_return(%w[add_contact_note])
      allow(described_class).to receive(:built_in_agent_tools).and_return([
                                                                            { id: 'add_contact_note', title: 'Add Contact Note',
                                                                              description: 'Add a note' }
                                                                          ])
    end

    describe '#resolved_tools' do
      it 'includes custom tool metadata' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order',
                                     title: 'Fetch Order', description: 'Gets order details')
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Fetch Order](tool://custom_fetch-order)')

        resolved = scenario.send(:resolved_tools)
        expect(resolved.length).to eq(1)
        expect(resolved.first[:id]).to eq('custom_fetch-order')
        expect(resolved.first[:title]).to eq('Fetch Order')
        expect(resolved.first[:description]).to eq('Gets order details')
      end

      it 'includes both static and custom tools' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Add Note](tool://add_contact_note) and [@Fetch Order](tool://custom_fetch-order)')

        resolved = scenario.send(:resolved_tools)
        expect(resolved.length).to eq(2)
        expect(resolved.map { |t| t[:id] }).to contain_exactly('add_contact_note', 'custom_fetch-order')
      end

      it 'excludes disabled custom tools' do
        custom_tool = create(:captain_custom_tool, account: account, slug: 'custom_fetch-order', enabled: true)
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Fetch Order](tool://custom_fetch-order)')

        custom_tool.update!(enabled: false)

        resolved = scenario.send(:resolved_tools)
        expect(resolved).to be_empty
      end
    end

    describe '#resolve_tool_instance' do
      it 'returns HttpTool instance for custom tools' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = create(:captain_scenario, assistant: assistant, account: account)

        tool_metadata = { id: 'custom_fetch-order', custom: true }
        tool_instance = scenario.send(:resolve_tool_instance, tool_metadata)
        expect(tool_instance).to be_a(Captain::Tools::HttpTool)
      end

      it 'returns nil for disabled custom tools' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order', enabled: false)
        scenario = create(:captain_scenario, assistant: assistant, account: account)

        tool_metadata = { id: 'custom_fetch-order', custom: true }
        tool_instance = scenario.send(:resolve_tool_instance, tool_metadata)
        expect(tool_instance).to be_nil
      end

      it 'returns static tool instance for non-custom tools' do
        scenario = create(:captain_scenario, assistant: assistant, account: account)
        allow(described_class).to receive(:resolve_tool_class).with('add_contact_note').and_return(
          Class.new do
            def initialize(_assistant); end
          end
        )

        tool_metadata = { id: 'add_contact_note' }
        tool_instance = scenario.send(:resolve_tool_instance, tool_metadata)
        expect(tool_instance).not_to be_nil
        expect(tool_instance).not_to be_a(Captain::Tools::HttpTool)
      end
    end

    describe '#agent_tools' do
      it 'returns array of tool instances including custom tools' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Fetch Order](tool://custom_fetch-order)')

        tools = scenario.send(:agent_tools)
        expect(tools.length).to eq(1)
        expect(tools.first).to be_a(Captain::Tools::HttpTool)
      end

      it 'excludes disabled custom tools from execution' do
        custom_tool = create(:captain_custom_tool, account: account, slug: 'custom_fetch-order', enabled: true)
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Fetch Order](tool://custom_fetch-order)')

        custom_tool.update!(enabled: false)

        tools = scenario.send(:agent_tools)
        expect(tools).to be_empty
      end

      it 'returns mixed static and custom tool instances' do
        create(:captain_custom_tool, account: account, slug: 'custom_fetch-order')
        scenario = create(:captain_scenario,
                          assistant: assistant,
                          account: account,
                          instruction: 'Use [@Add Note](tool://add_contact_note) and [@Fetch Order](tool://custom_fetch-order)')

        allow(described_class).to receive(:resolve_tool_class).with('add_contact_note').and_return(
          Class.new do
            def initialize(_assistant); end
          end
        )

        tools = scenario.send(:agent_tools)
        expect(tools.length).to eq(2)
        expect(tools.last).to be_a(Captain::Tools::HttpTool)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid scenario with associations' do
      account = create(:account)
      assistant = create(:captain_assistant, account: account)
      scenario = build(:captain_scenario, assistant: assistant, account: account)
      expect(scenario).to be_valid
    end

    it 'creates a scenario with all required attributes' do
      scenario = create(:captain_scenario)
      expect(scenario.title).to be_present
      expect(scenario.description).to be_present
      expect(scenario.instruction).to be_present
      expect(scenario.enabled).to be true
      expect(scenario.assistant).to be_present
      expect(scenario.account).to be_present
    end
  end
end
