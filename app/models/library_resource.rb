# == Schema Information
#
# Table name: library_resources
#
#  id          :bigint           not null, primary key
#  content     :text
#  description :text             not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#
# Indexes
#
#  index_library_resources_on_account_id  (account_id)
#  index_library_resources_on_title       (title)
#
class LibraryResource < ApplicationRecord
  belongs_to :account

  validates :title, presence: true
  validates :description, presence: true
  validates :account, presence: true
end
