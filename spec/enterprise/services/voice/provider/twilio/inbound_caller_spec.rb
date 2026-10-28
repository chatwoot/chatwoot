require 'rails_helper'

RSpec.describe Voice::Provider::Twilio::InboundCaller do
  let(:account) { create(:account) }
  let(:call_sid) { "CA#{SecureRandom.hex(16)}" }

  describe '#build' do
    ['anonymous', '', 'restricted', 'unknown', '+266696687', '+86282452253', '+8656696', '+2562533', '+7378742833', '+464'].each do |from|
      it "creates a phone-less caller for #{from.inspect}" do
        caller = described_class.new(from: from, call_sid: call_sid, account: account).build

        expect(caller).to eq(source_ids: ["anonymous:#{call_sid}"], contact_attributes: { name: 'Unknown caller' })
      end
    end

    it 'preserves a normal caller phone number' do
      from = '+14157047320'
      caller = described_class.new(from: from, call_sid: call_sid, account: account).build

      expect(caller).to eq(source_ids: [from], contact_attributes: { name: from, phone_number: from })
    end
  end
end
