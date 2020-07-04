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
#  account_id  :integer
#
class Kbase::Category < ApplicationRecord
  belongs_to :account
  has_many :portal_categories
  has_many :portals, through: :portal_categories
  has_many :folders
  has_many :articles

  validates :account_id, presence: true
  validates :name, presence: true
end
