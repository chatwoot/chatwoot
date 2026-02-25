# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSetting do
  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end
end
