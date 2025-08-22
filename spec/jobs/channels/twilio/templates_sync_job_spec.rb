require 'rails_helper'

RSpec.describe Channels::Twilio::TemplatesSyncJob do
  let!(:account) { create(:account) }
  let!(:twilio_channel) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }

  it 'enqueues the job' do
    expect { described_class.perform_later(twilio_channel) }.to have_enqueued_job(described_class)
      .on_queue('low')
      .with(twilio_channel)
  end

  describe '#perform' do
    context 'with successful sync_templates' do
      it 'calls sync_templates on the channel' do
        expect(twilio_channel).to receive(:sync_templates).and_return(true)

        described_class.perform_now(twilio_channel)
      end
    end

    context 'with sync_templates exception' do
      let(:error_message) { 'Twilio API error' }

      before do
        allow(twilio_channel).to receive(:sync_templates).and_raise(StandardError, error_message)
        allow(Rails.logger).to receive(:error)
      end

      it 'does not suppress the exception' do
        expect { described_class.perform_now(twilio_channel) }.to raise_error(StandardError, error_message)
      end
    end

    context 'with nil channel' do
      it 'handles nil channel gracefully' do
        expect { described_class.perform_now(nil) }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'job configuration' do
    it 'is configured to run on low priority queue' do
      expect(described_class.queue_name).to eq('low')
    end
  end
end
