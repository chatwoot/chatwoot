# frozen_string_literal: true

class PurgeExpiredAppointmentQrCodesJob < ApplicationJob
  queue_as :housekeeping

  def perform
    appointments_to_purge = Appointment
                            .where('DATE(end_time) = ?', Date.current)
                            .where.associated(:qr_code_attachment)

    appointments_to_purge.find_each do |appointment|
      appointment.qr_code.purge_later
      Rails.logger.info("Scheduled QR code purge for appointment #{appointment.id}")
    end

    Rails.logger.info("Scheduled QR code purge for #{appointments_to_purge.count} appointments ending today")
  end
end
