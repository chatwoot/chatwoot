# == Schema Information
#
# Table name: kbase_articles
#
#  id          :bigint           not null, primary key
#  content     :text
#  description :text
#  status      :integer
#  title       :string
#  views       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  author_id   :integer
#  category_id :integer
#  folder_id   :integer
#
class Kbase::Article < ApplicationRecord
  belongs_to :account
  belongs_to :category
  belongs_to :folder
  belongs_to :author, class_name: 'User'

  validates :account_id, presence: true
  validates :category_id, presence: true
  validates :author_id, presence: true

  validates :title, presence: true
  validates :content, presence: true

  enum status: { draft: 0, published: 1 }
end
