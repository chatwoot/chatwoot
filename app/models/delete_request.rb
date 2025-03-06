# == Schema Information
#
# Table name: delete_requests
#
#  id                :bigint           not null, primary key
#  completed_at      :datetime
#  confirmation_code :string           not null
#  deleted_type      :string
#  status            :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint
#  deleted_id        :integer
#  fb_id             :string           not null
#
# Indexes
#
#  index_delete_requests_on_account_id         (account_id)
#  index_delete_requests_on_confirmation_code  (confirmation_code) UNIQUE
#
class DeleteRequest < ApplicationRecord
  belongs_to :account
end
