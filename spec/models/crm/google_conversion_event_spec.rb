require 'rails_helper'

RSpec.describe Crm::GoogleConversionEvent do
  describe 'validations' do
    it 'is valid with the required attributes' do
      expect(build(:crm_google_conversion_event)).to be_valid
    end

    it 'accepts only ready or skipped statuses' do
      event = build(:crm_google_conversion_event, status: 'pending')

      expect(event).not_to be_valid
      expect(event.errors[:status]).to be_present
    end

    it 'enforces event_id uniqueness at the database level' do
      original = create(:crm_google_conversion_event)

      expect do
        create(:crm_google_conversion_event, account: original.account, event_id: original.event_id)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'requires a three-letter currency when currency is present' do
      expect(build(:crm_google_conversion_event, currency: 'REAL')).not_to be_valid
    end

    it 'requires a gclid for ready events' do
      expect(build(:crm_google_conversion_event, gclid: nil)).not_to be_valid
    end

    it 'requires a reason for skipped events' do
      expect(build(:crm_google_conversion_event, status: 'skipped', gclid: nil, skip_reason: nil)).not_to be_valid
    end
  end

  describe '.ready' do
    it 'returns only feed-ready events' do
      ready = create(:crm_google_conversion_event)
      create(:crm_google_conversion_event, status: 'skipped', gclid: nil, skip_reason: 'missing_gclid')

      expect(described_class.ready).to contain_exactly(ready)
    end
  end
end
