require 'rails_helper'

RSpec.describe Workflow::AccountInboxTemplate, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_template_id) }
    it { is_expected.to validate_presence_of(:inbox_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:account_template) }
  end
end
