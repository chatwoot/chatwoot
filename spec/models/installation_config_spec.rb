# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstallationConfig do
  subject { build(:installation_config) }

  it { is_expected.to validate_presence_of(:name) }

  describe 'primary color validation' do
    let(:config) do
      build(:installation_config, name: InstallationConfig::PRIMARY_COLOR_NAME, value: value, locked: false)
    end

    context 'with a valid hex value' do
      let(:value) { '#1A2B3C' }

      it 'is valid' do
        expect(config).to be_valid
      end
    end

    context 'with lowercase hex characters' do
      let(:value) { '#1a2b3c' }

      it 'normalizes the value before validation' do
        expect(config).to be_valid
        expect(config.value).to eq('#1A2B3C')
      end
    end

    context 'without the leading hash' do
      let(:value) { '1A2B3C' }

      it 'is not valid' do
        expect(config).not_to be_valid
        expect(config.errors[:value]).to include('must be a valid hex color in #RRGGBB format')
      end
    end

    context 'with an invalid hex length' do
      let(:value) { '#1A2B3' }

      it 'is not valid' do
        expect(config).not_to be_valid
        expect(config.errors[:value]).to include('must be a valid hex color in #RRGGBB format')
      end
    end

    context 'when the value is blank' do
      let(:value) { nil }

      it 'is not valid' do
        expect(config).not_to be_valid
        expect(config.errors[:value]).to include('must be a valid hex color in #RRGGBB format')
      end
    end
  end
end
