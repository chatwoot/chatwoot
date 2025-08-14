# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::AgentCapacityPolicy do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inbox_capacity_limits).dependent(:destroy) }
    it { is_expected.to have_many(:account_users).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:account) }
  end
end
