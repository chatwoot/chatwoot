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

    describe 'before_save :populate_tools' do
      it 'calls populate_tools before saving' do
        scenario = build(:captain_scenario, assistant: assistant, account: account)
        expect(scenario).to receive(:populate_tools)
        scenario.save
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
