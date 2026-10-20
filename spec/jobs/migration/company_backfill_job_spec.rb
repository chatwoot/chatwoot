require 'rails_helper'

RSpec.describe Migration::CompanyBackfillJob, type: :job do
  describe '#perform' do
    it 'enqueues the job' do
      expect { described_class.perform_later }
        .to have_enqueued_job(described_class)
        .on_queue('low')
    end

    context 'when accounts exist' do
      let!(:account1) { create(:account) }
      let!(:account2) { create(:account) }

      it 'enqueues CompanyAccountBatchJob for each account' do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Migration::CompanyAccountBatchJob)
          .with(account1)
          .and have_enqueued_job(Migration::CompanyAccountBatchJob)
          .with(account2)
      end
    end

    context 'when no accounts exist' do
      it 'completes without error' do
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
