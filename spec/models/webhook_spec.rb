require 'rails_helper'

RSpec.describe Webhook, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end
end
