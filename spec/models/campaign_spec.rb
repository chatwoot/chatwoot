# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Campaign, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe '.before_create' do
    let(:campaign) { build(:campaign, display_id: nil) }

    before do
      campaign.save
      campaign.reload
    end

    it 'runs before_create callbacks' do
      expect(campaign.display_id).to eq(1)
    end
  end
end
