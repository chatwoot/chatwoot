require 'rails_helper'

RSpec.describe ParquetReport, type: :model do
  subject { described_class.create(account: account, user: user) }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:record_count) { 100 }

  describe '#in_progress!' do
    it 'updates the status to in_progress and sets record_count' do
      subject.in_progress!(record_count: record_count)
      expect(subject.status).to eq(ParquetReport::IN_PROGRESS)
      expect(subject.record_count).to eq(record_count)
    end
  end

  describe '#increment_progress' do
    before do
      subject.in_progress!(record_count: record_count)
    end

    it 'updates the progress by percentage' do
      subject.increment_progress(processed_count: 10)
      expect(subject.progress).to eq(10)
    end

    context 'when processed count is greater than record count' do
      let(:record_count) { 9 }
      it 'sets progress to 99 unless status is completed' do
        subject.increment_progress(processed_count: 100)
        expect(subject.progress).to eq(99)
      end
    end
  end

  describe '#complete_and_save_url!' do
    it 'updates the report with completed status and file URL' do
      subject.complete_and_save_url!('http://example.com/file.parquet')

      expect(subject.status).to eq(ParquetReport::COMPLETED)
      expect(subject.file_url).to eq('http://example.com/file.parquet')
      expect(subject.progress).to eq(100)
    end
  end
end
