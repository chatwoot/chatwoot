require 'rails_helper'

RSpec.describe Crm::MetaConversionEvent do
  let(:account) { create(:account) }

  def build_event(attrs = {})
    described_class.new({ account: account, event_id: 'crm-1-won-9', event_type: 'won' }.merge(attrs))
  end

  describe 'validations' do
    it 'is valid with the required attributes' do
      expect(build_event).to be_valid
    end

    it 'requires an event_id' do
      event = build_event(event_id: nil)

      expect(event).not_to be_valid
      expect(event.errors[:event_id]).to be_present
    end

    it 'requires an event_type' do
      event = build_event(event_type: nil)

      expect(event).not_to be_valid
      expect(event.errors[:event_type]).to be_present
    end

    it 'enforces event_id uniqueness at the database level (the Meta dedup key)' do
      build_event.save!
      duplicate = build_event

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'status enum' do
    it 'defaults to pending and exposes the terminal states' do
      expect(build_event.status).to eq('pending')
      expect(described_class.statuses.keys).to match_array(%w[pending accepted skipped error])
    end
  end

  describe 'defaults' do
    it 'defaults source to live' do
      expect(build_event.source).to eq('live')
    end
  end

  describe '.recentes' do
    it 'orders by created_at descending' do
      older = build_event(event_id: 'e-old', created_at: 2.days.ago).tap(&:save!)
      newer = build_event(event_id: 'e-new', created_at: 1.hour.ago).tap(&:save!)

      expect(described_class.recentes.to_a).to eq([newer, older])
    end
  end
end
