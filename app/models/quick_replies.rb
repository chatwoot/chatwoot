# == Schema Information
#
# Table name: quick_replies
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  content    :text             not null
#  account_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class QuickReply < ApplicationRecord
  belongs_to :account

  validates :name, :content, presence: true
end
