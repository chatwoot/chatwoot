# == Schema Information
#
# Table name: channel_groups
#
#  id         :bigint           not null, primary key
#  name       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_channel_groups_on_account_id           (account_id)
#  index_channel_groups_on_account_id_and_name  (account_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class ChannelGroup < ApplicationRecord
  belongs_to :account
  has_many :inboxes, dependent: :nullify

  before_validation :strip_name

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { scope: :account_id, case_sensitive: false }

  private

  def strip_name
    self.name = name&.strip
  end
end
