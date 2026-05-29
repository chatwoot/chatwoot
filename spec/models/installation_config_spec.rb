# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstallationConfig do
  subject(:installation_config) { described_class.new(name: 'INSTALLATION_NAME') }

  it { is_expected.to validate_presence_of(:name) }

  describe 'new record defaults' do
    it 'initializes serialized_value with indifferent access' do
      expect(installation_config.serialized_value).to eq({}.with_indifferent_access)
    end

    it 'returns nil for value before assignment' do
      expect(installation_config.value).to be_nil
    end
  end

  describe '.latest_first' do
    it 'orders editable records by created_at desc without default_scope' do
      older = create(:installation_config, name: 'OLDER_CONFIG', value: 'old', locked: false, created_at: 2.days.ago)
      newer = create(:installation_config, name: 'NEWER_CONFIG', value: 'new', locked: false, created_at: 1.day.ago)

      expect(described_class.editable.latest_first.first).to eq(newer)
      expect(described_class.editable.latest_first.second).to eq(older)
    end
  end
end
