require 'rails_helper'

RSpec.describe Captain::EmailVerificationMailer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, name: 'Acme Support') }
  # Built from the queued job's arguments, so the specs cover the encryption round trip
  let(:mail) do
    described_class.deliver_code_later(inbox, 'jane@example.com', '482913')
    job_arguments = ActiveJob::Arguments.deserialize(ActiveJob::Base.queue_adapter.enqueued_jobs.last['arguments']).last
    described_class.with(job_arguments[:params]).verification_code(*job_arguments[:args]).message
  end

  it 'sends the code to the address, from the inbox name' do
    expect(mail.to).to eq(['jane@example.com'])
    expect(mail[:from].display_names).to eq(['Acme Support'])
    expect(mail.body.encoded).to include('482913').and include('30 minutes')
  end

  it 'keeps the code out of the subject' do
    expect(mail.subject).to eq('Your Acme Support verification code')
  end

  it 'keeps an inbox name with a comma as one sender' do
    inbox.update!(name: 'Acme, Inc')

    expect(mail[:from].addrs.map { |address| [address.display_name, address.address] }).to eq([['Acme, Inc', mail.from.first]])
    expect(mail.from.size).to eq(1)
  end

  it 'takes the subject and the body text from translations' do
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with('captain.email_verification.subject', inbox_name: 'Acme Support').and_return('Votre code')
    allow(I18n).to receive(:t).with('captain.email_verification.heading').and_return('Votre code de verification')

    expect(mail.subject).to eq('Votre code')
    expect(mail.body.encoded).to include('Votre code de verification')
  end

  describe '.deliver_code_later' do
    it 'never passes the plain code to the mail job' do
      described_class.deliver_code_later(inbox, 'jane@example.com', '482913')

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(job['job_class']).to eq('ActionMailer::MailDeliveryJob')
      expect(job['arguments'].to_s).not_to include('482913')
    end
  end

  describe '.deliverable?' do
    it 'is false when SMTP is not configured' do
      with_modified_env SMTP_ADDRESS: nil do
        expect(described_class.deliverable?).to be(false)
      end
    end

    it 'is true when SMTP is configured' do
      with_modified_env SMTP_ADDRESS: 'smtp.example.com' do
        expect(described_class.deliverable?).to be(true)
      end
    end
  end
end
