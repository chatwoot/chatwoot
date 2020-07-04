# == Schema Information
#
# Table name: kbase_articles
#
#  id              :bigint           not null, primary key
#  content         :text
#  seo_description :string
#  seo_title       :string
#  status          :integer
#  title           :string
#  views           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer
#  author_id       :integer
#  category_id     :integer
#  folder_id       :integer
#
class Kbase::Article < ApplicationRecord
  belongs_to :account
  belongs_to :category
  belongs_to :folder
  belongs_to :author, class_name: 'User'
end
