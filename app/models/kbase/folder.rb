# == Schema Information
#
# Table name: kbase_folders
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  category_id :integer
#
class Kbase::Folder < ApplicationRecord
  belongs_to :account
  belongs_to :category
end
