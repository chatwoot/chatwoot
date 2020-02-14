# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  urls       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  inbox_id   :integer
#

class Webhook < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  serialize :urls, Array
end
