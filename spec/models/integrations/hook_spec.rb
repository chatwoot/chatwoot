require 'rails_helper'

RSpec.describe Integrations::Hook, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:app_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end
end
