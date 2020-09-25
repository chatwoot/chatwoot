# == Schema Information
#
# Table name: kbase_folders
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#  category_id :integer          not null
#
class Kbase::Folder < ApplicationRecord
  belongs_to :account
  belongs_to :category
  has_many :articles, dependent: :nullify

  validates :account_id, presence: true
  validates :category_id, presence: true
  validates :name, presence: true
end
