require 'rails_helper'

describe Digitaltolk::WebflowService do
  let(:service) { described_class.new(params) }

  let(:params) do
    ActionController::Parameters.new(webhook_data)
  end

  let(:webhook_data) do
    {
      'params': {
        'webflow': {
          'triggerType': 'form_submission',
          'payload': {
            'name': 'Info kontakt',
            'siteId': '6476e981f6a8eff9068d9af2',
            'data': {
              'Name-kom': 'Test JM',
              'Email-kom': 'test@test.com',
              'phone-kom': '',
              'Bok. nr.': '#3364311',
              'Subject': 'Mejl för tolk',
              'Meddelande': 'Hej! Har bokat tolk men ser inte tolkens mejladress någonstans. Behöver den för att skicka video länk.',
              'recipient': recipient
            }
          }
        }
      }
    }
  end

  let(:recipient) { 'info@example.com' }

  before do
    service.perform
  end

  it 'has no errors' do
    service.perform
    expect(service.errors).to eq([])
  end

  it 'triggers digitaltolk email worker' do
    worker_double = instance_double(DigitaltolkEmailWorker)
    allow(DigitaltolkEmailWorker).to receive(:perform_in).and_return(worker_double)
    allow(worker_double).to receive(:perform)

    service.perform

    expect(DigitaltolkEmailWorker).to have_received(:perform_in)
  end

  context 'with invalid email' do
    let(:recipient) { 'example@@example.com' }

    it 'does not trigger email worker' do
      worker_double = instance_double(DigitaltolkEmailWorker)
      allow(DigitaltolkEmailWorker).to receive(:perform_in).and_return(worker_double)
      allow(worker_double).to receive(:perform)

      service.perform

      expect(DigitaltolkEmailWorker).not_to have_received(:perform_in)
    end
  end

  context 'with multiple email' do
    let(:recipient) { 'info@example.com, info2@example.com' }

    it 'does not trigger email worker' do
      worker_double = instance_double(DigitaltolkEmailWorker)
      allow(DigitaltolkEmailWorker).to receive(:perform_in).and_return(worker_double)
      allow(worker_double).to receive(:perform)

      service.perform

      expect(DigitaltolkEmailWorker).to have_received(:perform_in).twice
    end
  end
end
