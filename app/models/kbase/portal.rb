# == Schema Information
#
# Table name: kbase_portals
#
#  id            :bigint           not null, primary key
#  account_id    :integer          not null
#  color         :string
#  custom_domain :string
#  header_text   :text
#  homepage_link :string
#  name          :string           not null
#  page_title    :string
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_kbase_portals_on_slug  (slug) UNIQUE
#
class Kbase::Portal < ApplicationRecord
  belongs_to :account
  has_many :categories, dependent: :destroy
  has_many :folders,  through: :categories
  has_many :articles, dependent: :destroy

  validates :account_id, presence: true
  validates :name, presence: true
  validates :slug, presence: true
end
