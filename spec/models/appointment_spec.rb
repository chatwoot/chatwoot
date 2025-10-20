# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Appointment do
  describe 'associations' do
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }

    context 'when end_time is before start_time' do
      let(:contact) { create(:contact) }
      let(:appointment) { build(:appointment, contact: contact, start_time: Time.zone.now, end_time: 1.hour.ago) }

      it 'is invalid' do
        expect(appointment).not_to be_valid
        expect(appointment.errors[:end_time]).to include('must be after start time')
      end
    end

    context 'when end_time is after start_time' do
      let(:contact) { create(:contact) }
      let(:appointment) { build(:appointment, contact: contact, start_time: Time.zone.now, end_time: 1.hour.from_now) }

      it 'is valid' do
        expect(appointment).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe 'access_token generation' do
      let(:contact) { create(:contact) }

      it 'generates access_token before create' do
        appointment = build(:appointment, contact: contact)
        expect(appointment.access_token).to be_nil

        appointment.save!
        expect(appointment.access_token).to be_present
        expect(appointment.access_token).to be_a(String)
      end

      it 'generates unique access_token for each appointment' do
        appointment1 = create(:appointment, contact: contact)
        appointment2 = create(:appointment, contact: contact)

        expect(appointment1.access_token).to be_present
        expect(appointment2.access_token).to be_present
        expect(appointment1.access_token).not_to eq(appointment2.access_token)
      end
    end
  end
end
