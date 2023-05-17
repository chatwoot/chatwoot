# == Schema Information
#
# Table name: custom_filters
#
#  id          :bigint           not null, primary key
#  filter_type :integer          default("conversation"), not null
#  name        :string           not null
#  query       :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_custom_filters_on_account_id  (account_id)
#  index_custom_filters_on_user_id     (user_id)
#
class CustomFilter < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum filter_type: { conversation: 0, contact: 1, report: 2 }
  validate :validate_number_of_filters

  def validate_number_of_filters
    return true if self.class.where(account_id: account_id, user_id: user_id).size <= 50

    errors.add :account_id, 'We do not allow creating >50 custom views per account per user'
  end
end
