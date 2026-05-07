require 'rails_helper'

RSpec.describe Note do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:contact_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:updated_by).class_name('User').optional }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'defaults' do
    it 'defaults source and metadata for timeline and agent context' do
      note = build(:note, source: nil, metadata: nil)
      note.valid?

      expect(note.source).to eq('manual')
      expect(note.metadata).to eq({})
    end
  end

  describe '#created_by' do
    it 'aliases the legacy user association as creator' do
      note = create(:note)

      expect(note.created_by).to eq(note.user)
    end
  end

  describe 'validates_factory' do
    it 'creates valid note object' do
      note = create(:note)
      expect(note.content).to eq 'Hey welcome to chatwoot'
    end
  end
end
