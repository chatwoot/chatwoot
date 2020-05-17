# == Schema Information
#
# Table name: conversation_participants
#
#  id              :bigint           not null, primary key
#  primary         :boolean          default(TRUE), not null
#  uuid            :uuid             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  contact_id      :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_conversation_participants_contact_conversation  (contact_id,conversation_id) UNIQUE
#  index_conversation_participants_on_contact_id         (contact_id)
#  index_conversation_participants_on_conversation_id    (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#

class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :contact
end
