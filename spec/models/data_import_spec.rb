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

  describe 'access token encryption' do
    it 'encrypts the Intercom access token at rest' do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?

      data_import = create(:data_import, :intercom, access_token: 'intercom-secret')
      stored_value = data_import.reload.read_attribute_before_type_cast(:access_token).to_s

      expect(stored_value).not_to include('intercom-secret')
      expect(data_import.access_token).to eq('intercom-secret')
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

  describe '#abandon!' do
    let(:account) { create(:account) }
    let(:data_import) do
      create(
        :data_import, :intercom,
        account: account,
        status: :processing
      )
    end

    before do
      account.enable_features!('data_import')
    end

    it 'abandons active Intercom imports', :aggregate_failures do
      data_import.abandon!

      expect(data_import).to be_abandoned
      expect(data_import.abandoned_at).to be_present
    end

    it 'does not overwrite terminal status from a stale instance', :aggregate_failures do
      stale_import = described_class.find(data_import.id)
      data_import.update!(status: :completed, completed_at: 1.minute.ago)

      stale_import.abandon!

      expect(data_import.reload).to be_completed
      expect(data_import.abandoned_at).to be_nil
    end
  end

  describe '#stalled?' do
    let(:account) { create(:account) }

    it 'identifies active Intercom imports without updates for fifteen minutes', :aggregate_failures do
      freeze_time do
        processing_import = create(:data_import, :intercom, account: account, status: :processing)
        pending_import = create(:data_import, :intercom, account: account, status: :pending)
        processing_import.update!(updated_at: 15.minutes.ago)
        pending_import.update!(updated_at: 15.minutes.ago)

        expect(processing_import.reload).to be_stalled
        expect(pending_import.reload).to be_stalled
      end
    end

    it 'does not identify recent or terminal Intercom imports as stalled', :aggregate_failures do
      recent_import = create(:data_import, :intercom, account: account, status: :processing)
      completed_import = create(:data_import, :intercom, account: account, status: :completed)
      completed_import.update!(updated_at: 1.hour.ago)

      expect(recent_import).not_to be_stalled
      expect(completed_import.reload).not_to be_stalled
    end

    it 'does not identify legacy imports as stalled' do
      legacy_import = create(:data_import, account: account, status: :processing)
      legacy_import.update!(updated_at: 1.hour.ago)

      expect(legacy_import.reload).not_to be_stalled
    end
  end
end
