require 'rails_helper'

RSpec.describe ConversationHandledByTag, type: :model do

  describe 'Associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:handled_by) }
  end
end
