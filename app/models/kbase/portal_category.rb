# == Schema Information
#
# Table name: kbase_portal_categories
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  category_id :integer
#  portal_id   :integer
#
class Kbase::PortalCategory < ApplicationRecord
  belongs_to :account
  belongs_to :portal
  belongs_to :category

  validates :account_id, presence: true
  validates :portal_id, presence: true
  validates :category_id, presence: true
end
