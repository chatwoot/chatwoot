# == Schema Information
#
# Table name: ottiv_calendar_item_contacts
#
#  id                       :bigint           not null, primary key
#  ottiv_calendar_item_id   :bigint           not null
#  contact_id               :bigint           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class OttivCalendarItemContact < ApplicationRecord
  belongs_to :ottiv_calendar_item
  belongs_to :contact

  validates :ottiv_calendar_item_id, uniqueness: { scope: :contact_id }
end

