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

class NotificationSetting < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu

  belongs_to :account
  belongs_to :user

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  EMAIL_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "email_#{key}".to_sym }.invert.freeze
  PUSH_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "push_#{key}".to_sym }.invert.freeze

  has_flags EMAIL_NOTIFICATION_FLAGS.merge(column: 'email_flags').merge(DEFAULT_QUERY_SETTING)
  has_flags PUSH_NOTIFICATION_FLAGS.merge(column: 'push_flags').merge(DEFAULT_QUERY_SETTING)
end
