# == Schema Information
#
# Table name: ottiv_calendar_item_participants
#
#  id                       :bigint           not null, primary key
#  ottiv_calendar_item_id   :bigint           not null
#  user_id                  :bigint           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class OttivCalendarItemParticipant < ApplicationRecord
  belongs_to :ottiv_calendar_item
  belongs_to :user

  validates :ottiv_calendar_item_id, uniqueness: { scope: :user_id }
end

