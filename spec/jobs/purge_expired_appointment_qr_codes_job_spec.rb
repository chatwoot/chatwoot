# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeExpiredAppointmentQrCodesJob, type: :job do
  subject(:job) { described_class.perform_later }

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('housekeeping')
  end

  describe '#perform' do
    let!(:appointment_ending_today_with_qr) do
      create(:appointment,
             contact: contact,
             account: account,
             start_time: Time.zone.now.beginning_of_day,
             end_time: Time.zone.now.end_of_day).tap do |appointment|
        appointment.qr_code.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'qr_code.png',
          content_type: 'image/png'
        )
      end
    end

    let!(:appointment_ending_today_without_qr) do
      create(:appointment,
             contact: contact,
             account: account,
             start_time: Time.zone.now.beginning_of_day,
             end_time: Time.zone.now.end_of_day)
    end

    let!(:appointment_ending_tomorrow_with_qr) do
      create(:appointment,
             contact: contact,
             account: account,
             start_time: 1.day.from_now.beginning_of_day,
             end_time: 1.day.from_now.end_of_day).tap do |appointment|
        appointment.qr_code.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'qr_code.png',
          content_type: 'image/png'
        )
      end
    end

    let!(:appointment_ended_yesterday_with_qr) do
      create(:appointment,
             contact: contact,
             account: account,
             start_time: 1.day.ago.beginning_of_day,
             end_time: 1.day.ago.end_of_day).tap do |appointment|
        appointment.qr_code.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'qr_code.png',
          content_type: 'image/png'
        )
      end
    end

    it 'purges QR codes from appointments ending today' do
      expect(appointment_ending_today_with_qr.qr_code).to be_attached

      described_class.new.perform

      expect(appointment_ending_today_with_qr.reload.qr_code).not_to be_attached
    end

    it 'does not purge QR codes from appointments ending on other days' do
      expect(appointment_ending_tomorrow_with_qr.qr_code).to be_attached
      expect(appointment_ended_yesterday_with_qr.qr_code).to be_attached

      described_class.new.perform

      expect(appointment_ending_tomorrow_with_qr.reload.qr_code).to be_attached
      expect(appointment_ended_yesterday_with_qr.reload.qr_code).to be_attached
    end

    it 'does not fail when appointments have no QR code' do
      expect { described_class.new.perform }.not_to raise_error
    end

    it 'logs the purge operation' do
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with(/Scheduled QR code purge for appointment/)
      expect(Rails.logger).to have_received(:info).with(/Scheduled QR code purge for \d+ appointments ending today/)
    end
  end
end
