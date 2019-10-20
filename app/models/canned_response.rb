class CannedResponse < ApplicationRecord
  validates_presence_of :content
  validates_presence_of :short_code
  validates_presence_of :account
  validates_uniqueness_of :short_code, scope: :account_id

  belongs_to :account
end
