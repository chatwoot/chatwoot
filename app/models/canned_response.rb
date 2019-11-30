# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#

class CannedResponse < ApplicationRecord
  validates_presence_of :content
  validates_presence_of :short_code
  validates_presence_of :account
  validates_uniqueness_of :short_code, scope: :account_id

  belongs_to :account
end
