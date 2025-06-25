require 'rails_helper'

RSpec.describe DataImport do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it 'returns false for invalid data type' do
      expect(build(:data_import, data_type: 'Xyc').valid?).to be false
    end
  end
end
