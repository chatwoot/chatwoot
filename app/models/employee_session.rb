class EmployeeSession < ApplicationRecord
  belongs_to :user
  belongs_to :account, optional: true

  scope :open, -> { where(signed_out_at: nil) }
  scope :recent, -> { order(Arel.sql('COALESCE(last_seen_at, signed_in_at) DESC')) }

  def open?
    signed_out_at.blank?
  end
end
