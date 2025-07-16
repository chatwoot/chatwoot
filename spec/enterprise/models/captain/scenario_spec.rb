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

        expect(described_class.enabled).to include(enabled_scenario)
        expect(described_class.enabled).not_to include(disabled_scenario)
      end
    end
  end

  describe 'callbacks' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    describe 'before_save :resolve_tool_references' do
      it 'calls resolve_tool_references before saving' do
        scenario = build(:captain_scenario, assistant: assistant, account: account)
        expect(scenario).to receive(:resolve_tool_references)
        scenario.save
      end
    end
  end

  describe 'tool validation and population' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }

    before do
      # Mock available tools
      allow(described_class).to receive(:available_tool_ids).and_return(%w[
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
