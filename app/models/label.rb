# == Schema Information
#
# Table name: labels
#
#  id              :bigint           not null, primary key
#  color           :string
#  description     :text
#  show_on_sidebar :boolean
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint
#
# Indexes
#
#  index_labels_on_account_id  (account_id)
#
class Label < ApplicationRecord
  belongs_to :account
end
