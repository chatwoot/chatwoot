# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  contact_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_notes_on_account_id  (account_id)
#  index_notes_on_contact_id  (contact_id)
#  index_notes_on_user_id     (user_id)
#
class Note < ApplicationRecord
  before_validation :ensure_account_id
  validates :content, presence: true
  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :user_id, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :user

  scope :latest, -> { order(created_at: :desc) }

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end
end
