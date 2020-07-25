# == Schema Information
#
# Table name: kbase_portals
#
#  id                 :bigint           not null, primary key
#  color              :string
#  custom_domain      :string
#  favicon            :string
#  footer_title       :string
#  footer_url         :string
#  header_image       :string
#  header_text        :text
#  homepage_link      :string
#  logo               :string
#  name               :string
#  page_title         :string
#  social_media_image :string
#  subdomain          :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer
#
class Kbase::Portal < ApplicationRecord
  belongs_to :account
  has_many :portal_categories, dependent: :destroy
  has_many :categories, through: :portal_categories
  has_many :folders,  through: :categories
  has_many :articles, through: :folders

  validates :account_id, presence: true
  validates :name, presence: true
  validates :subdomain, presence: true
end
