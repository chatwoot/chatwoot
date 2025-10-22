# == Schema Information
#
# Table name: number_format_configs
#
#  id             :bigint           not null, primary key
#  current_number :integer          default(1)
#  format         :string           default("INV/")
#  reset_every    :string           default("never")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_number_format_configs_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class NumberFormatConfig < ApplicationRecord
  belongs_to :account

  validates :account_id, uniqueness: true
  validates :format, presence: true
  validates :current_number, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
