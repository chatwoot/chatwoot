# == Schema Information
#
# Table name: contact_bookings
#
#  id                :bigint           not null, primary key
#  booking_endTime   :datetime
#  booking_eventtype :string
#  booking_location  :string
#  booking_startTime :datetime
#  booking_uid       :string
#  host_name         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_contact_bookings_on_account_id  (account_id)
#  index_contact_bookings_on_contact_id  (contact_id)
#  index_contact_bookings_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (user_id => users.id)
#
class ContactBooking < ApplicationRecord
  belongs_to :user
  belongs_to :contact
  belongs_to :account
end
