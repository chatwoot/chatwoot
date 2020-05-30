# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationParticipant do
  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
  end
end
