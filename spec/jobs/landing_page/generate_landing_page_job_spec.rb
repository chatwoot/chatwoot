# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LandingPage::GenerateLandingPageJob, type: :job do
  let(:account) { create(:account) }
  let(:channel_widget) { create(:channel_widget, account: account, auto_generate_landing_page: true) }
  let(:inbox) { channel_widget.inbox }

  describe '#perform' do
    context 'when inbox has a WebWidget channel with auto_generate_landing_page enabled' do
      it 'calls LandingPage::RequestLandingPageService' do
        service_instance = instance_double(LandingPage::RequestLandingPageService)
        allow(LandingPage::RequestLandingPageService).to receive(:new).with(inbox).and_return(service_instance)
        allow(service_instance).to receive(:perform)

        described_class.new.perform(inbox.id)

        expect(LandingPage::RequestLandingPageService).to have_received(:new).with(inbox)
        expect(service_instance).to have_received(:perform)
      end
    end

    context 'when inbox channel is not a WebWidget' do
      let(:api_channel) { create(:channel_api, account: account) }
      let(:api_inbox) { create(:inbox, channel: api_channel, account: account) }

      it 'does not call LandingPage::RequestLandingPageService' do
        allow(LandingPage::RequestLandingPageService).to receive(:new)

        described_class.new.perform(api_inbox.id)

        expect(LandingPage::RequestLandingPageService).not_to have_received(:new)
      end
    end

    context 'when auto_generate_landing_page is false' do
      let(:channel_widget_disabled) { create(:channel_widget, account: account, auto_generate_landing_page: false) }
      let(:inbox_disabled) { channel_widget_disabled.inbox }

      it 'does not call LandingPage::RequestLandingPageService' do
        allow(LandingPage::RequestLandingPageService).to receive(:new)

        described_class.new.perform(inbox_disabled.id)

        expect(LandingPage::RequestLandingPageService).not_to have_received(:new)
      end
    end

    context 'when an error occurs' do
      it 'logs the error and re-raises it' do
        allow(LandingPage::RequestLandingPageService).to receive(:new).and_raise(StandardError, 'API error')
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.new.perform(inbox.id)
        end.to raise_error(StandardError, 'API error')

        expect(Rails.logger).to have_received(:error).with(
          "[GENERATE_LANDING_PAGE_JOB] Error generating landing page for inbox #{inbox.id}: API error"
        )
      end
    end

    context 'when inbox does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.new.perform(999_999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
