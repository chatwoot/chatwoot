# == Schema Information
#
# Table name: kbase_portals
#
#  id            :bigint           not null, primary key
#  color         :string
#  config        :jsonb
#  custom_domain :string
#  header_text   :text
#  homepage_link :string
#  name          :string           not null
#  page_title    :string
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#
# Indexes
#
#  index_kbase_portals_on_slug  (slug) UNIQUE
#
class Kbase::Portal < ApplicationRecord
  belongs_to :account
  has_many :categories, dependent: :destroy_async
  has_many :folders,  through: :categories
  has_many :articles, dependent: :destroy_async

  validates :account_id, presence: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
