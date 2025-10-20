# frozen_string_literal: true

# == Schema Information
#
# Table name: appointments
#
#  id           :bigint           not null, primary key
#  access_token :string
#  assisted     :boolean          default(FALSE), not null
#  description  :text
#  end_time     :datetime
#  location     :string
#  start_time   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  contact_id   :bigint           not null
#
# Indexes
#
#  index_appointments_on_access_token  (access_token) UNIQUE
#  index_appointments_on_account_id    (account_id)
#  index_appointments_on_contact_id    (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#

class Appointment < ApplicationRecord
  belongs_to :contact
  belongs_to :account

  has_one_attached :qr_code

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  before_create :generate_access_token

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, 'must be after start time') if end_time <= start_time
  end

  def generate_access_token
    self.access_token = SecureRandom.urlsafe_base64(32)
  end
end
