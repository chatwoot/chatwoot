# == Schema Information
#
# Table name: canned_response_inboxes
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  canned_response_id :bigint           not null
#  inbox_id           :bigint           not null
#
# Indexes
#
#  index_canned_response_inboxes_on_canned_response_id  (canned_response_id)
#  index_canned_response_inboxes_on_inbox_id            (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (canned_response_id => canned_responses.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class CannedResponseInbox < ApplicationRecord
  belongs_to :canned_response
  belongs_to :inbox
end
