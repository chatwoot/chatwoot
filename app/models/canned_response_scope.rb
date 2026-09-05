# == Schema Information
#
# Table name: canned_response_scopes
#
#  id                 :bigint           not null, primary key
#  inbox_ids          :integer          default([]), is an Array
#  team_ids           :integer          default([]), is an Array
#  user_ids           :integer          default([]), is an Array
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  canned_response_id :bigint           not null
#
# Indexes
#
#  index_canned_response_scopes_on_canned_response_id  (canned_response_id)
#
# Foreign Keys
#
#  fk_rails_...  (canned_response_id => canned_responses.id)
#
class CannedResponseScope < ApplicationRecord
  belongs_to :canned_response
end
