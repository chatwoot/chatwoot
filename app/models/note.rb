# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  author_id  :integer
#  contact_id :integer
#
class Note < ApplicationRecord
  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :author_id, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :user, class_name: 'User', foreign_key: 'author_id'
end
