# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketingCampaign, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:title).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:start_date).of_type(:date) }
    it { is_expected.to have_db_column(:end_date).of_type(:date) }
    it { is_expected.to have_db_column(:active).of_type(:boolean) }
    it { is_expected.to have_db_column(:source_id).of_type(:string) }
    it { is_expected.to have_db_column(:account_id).of_type(:integer) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:account) { create(:account) }
      let!(:active_campaign) { create(:marketing_campaign, active: true, account: account) }
      let!(:inactive_campaign) { create(:marketing_campaign, active: false, account: account) }

      it 'returns only active campaigns' do
        expect(described_class.active).to include(active_campaign)
        expect(described_class.active).not_to include(inactive_campaign)
      end
    end
  end
end
