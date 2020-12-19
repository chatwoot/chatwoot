# == Schema Information
#
# Table name: kbase_categories
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#  portal_id   :integer          not null
#
class Kbase::Category < ApplicationRecord
  belongs_to :account
  belongs_to :portal
  has_many :folders, dependent: :destroy
  has_many :articles, dependent: :nullify

  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :name, presence: true

  private

  def ensure_account_id
    self.account_id = portal&.account_id
  end
end
