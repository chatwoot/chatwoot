# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end
end
