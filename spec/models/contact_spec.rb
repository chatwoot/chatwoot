# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact do
  context 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  end
end
