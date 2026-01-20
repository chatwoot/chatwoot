# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriorityGroup, type: :model do
  subject { build(:priority_group) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it {
      expect(subject).to validate_uniqueness_of(:name)
        .scoped_to(:account_id)
    }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes).dependent(:destroy) }
  end
end
