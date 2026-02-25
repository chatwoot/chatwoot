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

  describe 'callbacks' do
    let(:data_import) { build(:data_import) }

    it 'schedules a job after creation' do
      expect do
        data_import.save
      end.to have_enqueued_job(DataImportJob).with(data_import).on_queue('low')
    end
  end
end
