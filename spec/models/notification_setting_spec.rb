# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id          :bigint           not null, primary key
#  email_flags :integer          default(0), not null
#  push_flags  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  user_id     :integer
#
# Indexes
#
#  by_account_user  (account_id,user_id) UNIQUE
#
require 'rails_helper'

RSpec.describe NotificationSetting do
  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end
end
