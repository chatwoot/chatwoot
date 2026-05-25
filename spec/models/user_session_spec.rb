require 'rails_helper'

RSpec.describe UserSession do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { described_class.new(user: user, client_id: 'abc') }

    it { is_expected.to validate_presence_of(:client_id) }

    it 'validates uniqueness of client_id scoped to user_id' do
      described_class.create!(user: user, client_id: 'abc', last_activity_at: Time.current)

      duplicate = described_class.new(user: user, client_id: 'abc')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:client_id]).to be_present
    end

    it 'allows the same client_id for different users' do
      other = create(:user)
      described_class.create!(user: user, client_id: 'abc', last_activity_at: Time.current)

      expect(described_class.new(user: other, client_id: 'abc', last_activity_at: Time.current)).to be_valid
    end
  end

  describe '#current?' do
    let(:session) { described_class.create!(user: user, client_id: 'abc', last_activity_at: Time.current) }

    it 'returns true when client_id matches' do
      expect(session.current?('abc')).to be true
    end

    it 'returns false when client_id differs' do
      expect(session.current?('xyz')).to be false
    end
  end

  describe '#should_update_activity?' do
    let(:session) { described_class.new(user: user, client_id: 'abc') }

    it 'returns true when last_activity_at is nil' do
      session.last_activity_at = nil
      expect(session.should_update_activity?).to be true
    end

    it 'returns true when last_activity_at is older than the throttle window' do
      session.last_activity_at = 10.minutes.ago
      expect(session.should_update_activity?).to be true
    end

    it 'returns false when last_activity_at is within the throttle window' do
      session.last_activity_at = 1.minute.ago
      expect(session.should_update_activity?).to be false
    end
  end
end
