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

  describe 'fields' do
    let(:data_import) { create(:data_import) }

    it 'has non_identifiable_records field with default value' do
      expect(data_import.non_identifiable_records).to eq(0)
    end

    it 'allows setting non_identifiable_records' do
      data_import.update!(non_identifiable_records: 5)
      expect(data_import.reload.non_identifiable_records).to eq(5)
    end
  end

  describe 'callbacks' do
    let(:data_import) { build(:data_import) }

    it 'schedules a job after creation' do
      expect do
        data_import.save
      end.to have_enqueued_job(DataImportJob).with(data_import).on_queue('low')
    end
  end
end
