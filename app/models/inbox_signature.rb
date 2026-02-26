# == Schema Information
#
# Table name: inbox_signatures
#
#  id                  :bigint           not null, primary key
#  message_signature   :text             not null
#  signature_position  :string           default("top"), not null
#  signature_separator :string           default("blank"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  inbox_id            :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_inbox_signatures_on_inbox_id              (inbox_id)
#  index_inbox_signatures_on_user_id_and_inbox_id  (user_id,inbox_id) UNIQUE
#

class InboxSignature < ApplicationRecord
  belongs_to :user
  belongs_to :inbox

  validates :message_signature, presence: true
  validates :user_id, uniqueness: { scope: :inbox_id }
  validates :signature_position, inclusion: { in: %w[top bottom] }
  validates :signature_separator, inclusion: { in: %w[blank --] }
end
