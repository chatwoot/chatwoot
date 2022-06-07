# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text
#  locale      :string           default("en")
#  name        :string
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#  portal_id   :integer          not null
#
# Indexes
#
#  index_categories_on_locale                 (locale)
#  index_categories_on_locale_and_account_id  (locale,account_id)
#
class Category < ApplicationRecord
  belongs_to :account
  belongs_to :portal
  has_many :folders, dependent: :destroy_async
  has_many :articles, dependent: :nullify

  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :name, presence: true

  private

  def ensure_account_id
    self.account_id = portal&.account_id
  end
end
