require 'rails_helper'

RSpec.describe CannedResponseScope, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:canned_response) }
  end

  describe 'factory' do
    it 'has a valid base factory' do
      expect(build(:canned_response_scope)).to be_valid
    end

    it 'has a valid user_scope trait' do
      expect(create(:canned_response_scope, :user_scope)).to be_valid
    end

    it 'has a valid team_scope trait' do
      expect(create(:canned_response_scope, :team_scope)).to be_valid
    end

    it 'has a valid inbox_scope trait' do
      expect(create(:canned_response_scope, :inbox_scope)).to be_valid
    end
  end

  describe 'attributes' do
    subject(:scope) { create(:canned_response_scope) }

    it 'has user_ids as array' do
      expect(scope.user_ids).to be_an(Array)
    end

    it 'has team_ids as array' do
      expect(scope.team_ids).to be_an(Array)
    end

    it 'has inbox_ids as array' do
      expect(scope.inbox_ids).to be_an(Array)
    end
  end
end
