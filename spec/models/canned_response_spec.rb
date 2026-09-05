require 'rails_helper'

RSpec.describe CannedResponse, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
    it { is_expected.to have_many(:canned_response_scopes).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:canned_response) }

    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:short_code) }
    it { is_expected.to validate_uniqueness_of(:short_code).scoped_to(:account_id) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:visibility).with_values(public_response: 0, private_response: 1) }
  end

  describe 'scopes' do
    describe '.order_by_search' do
      subject(:results) { account.canned_responses.order_by_search('hello') }

      let(:account) { create(:account) }
      let!(:exact_match)   { create(:canned_response, account: account, short_code: 'hello', content: 'world') }
      let!(:prefix_match)  { create(:canned_response, account: account, short_code: 'hello_world', content: 'foo') }
      let!(:content_match) { create(:canned_response, account: account, short_code: 'other', content: 'hello there') }
      let!(:no_match)      { create(:canned_response, account: account, short_code: 'zzz', content: 'zzz') }

      it 'returns all records sorted by relevance' do
        expect(results).to include(exact_match, prefix_match, content_match, no_match)
      end

      it 'ranks short_code prefix matches above content matches' do
        expect(results.index(exact_match)).to be < results.index(content_match)
        expect(results.index(prefix_match)).to be < results.index(content_match)
      end

      it 'ranks content matches above non-matches' do
        expect(results.index(content_match)).to be < results.index(no_match)
      end
    end

    describe '.accessible_to' do
      let(:account) { create(:account) }
      let(:user)    { create(:user, account: account) }
      let(:team)    { create(:team, account: account) }
      let(:inbox)   { create(:inbox, account: account) }

      let!(:public_response)  { create(:canned_response, account: account, visibility: :public_response) }
      let!(:private_response) { create(:canned_response, account: account, visibility: :private_response) }

      it 'includes public responses' do
        expect(described_class.accessible_to(user)).to include(public_response)
      end

      it 'excludes private responses without scope' do
        expect(described_class.accessible_to(user)).not_to include(private_response)
      end

      it 'includes private response scoped to user' do
        create(:canned_response_scope, canned_response: private_response, user_ids: [user.id])
        expect(described_class.accessible_to(user)).to include(private_response)
      end

      it 'includes private response scoped to user team' do
        create(:team_member, team: team, user: user)
        create(:canned_response_scope, canned_response: private_response, user_ids: [user.id], team_ids: [team.id])
        expect(described_class.accessible_to(user)).to include(private_response)
      end

      it 'includes private response scoped to user inbox' do
        create(:inbox_member, inbox: inbox, user: user)
        create(:canned_response_scope, canned_response: private_response, user_ids: [user.id], inbox_ids: [inbox.id])
        expect(account.canned_responses.accessible_to(user)).to include(private_response)
      end

      it 'includes private response created by user' do
        owned = create(:canned_response, account: account, visibility: :private_response, created_by: user)
        create(:canned_response_scope, canned_response: owned, user_ids: [user.id])
        expect(account.canned_responses.accessible_to(user)).to include(owned)
      end

      it 'does not duplicate results' do
        create(:canned_response_scope, canned_response: private_response, user_ids: [user.id])
        results = described_class.accessible_to(user)
        expect(results.to_a.count(private_response)).to eq(1)
      end
    end
  end
end
