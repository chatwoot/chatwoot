# == Schema Information
#
# Table name: message_quality_scores
#
#  id         :bigint           not null, primary key
#  scores     :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  message_id :bigint           not null
#
# Indexes
#
#  index_message_quality_scores_on_message_id  (message_id)
#
# Foreign Keys
#
#  fk_rails_...  (message_id => messages.id)
#
class MessageQualityScore < ApplicationRecord
  belongs_to :message
end
