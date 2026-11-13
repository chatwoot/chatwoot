require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe Enterprise::DeviceVerificationMailer do
  include_context 'with smtp config'

  let(:user) { create(:user, email: 'agent@example.com') }
  let(:meta) { { ip: '203.0.113.7', browser_name: 'Chrome', platform_name: 'macOS' } }

  describe '#verification_code' do
    let(:mail) { described_class.verification_code(user, DeviceVerification.encrypt_code('123456'), meta).message }

    it 'raises rather than silently no-opping when SMTP is not configured' do
      with_modified_env('SMTP_ADDRESS' => nil) do
        expect do
          described_class.verification_code(user, DeviceVerification.encrypt_code('123456'), meta).message
        end.to raise_error(/SMTP is not configured/)
      end
    end

    it 'sends the code to the user with device details' do
      expect(mail.to).to eq(['agent@example.com'])
      expect(mail.subject).to include('verification code')
      expect(mail.body.encoded).to include('123456')
      expect(mail.body.encoded).to include('203.0.113.7')
      expect(mail.body.encoded).to include('Chrome')
      expect(mail.body.encoded).to include('10 minutes')
    end

    it 'reassures without a reset pointer or accusatory language' do
      expect(mail.body.encoded).to include("If this wasn't you, you can safely ignore this email")
      expect(mail.body.encoded).not_to match(/knows your password/i)
      expect(mail.body.encoded).not_to include('/app/auth/reset/password')
    end

    it 'resolves and shows the sign-in location from the IP' do
      geo = Struct.new(:city, :country).new('Mumbai', 'India')
      allow(IpLookupService).to receive(:new).and_return(instance_double(IpLookupService, perform: geo))

      expect(mail.body.encoded).to include('Mumbai, India')
    end

    it 'omits a blank city instead of rendering a leading comma' do
      geo = Struct.new(:city, :country).new('', 'United States')
      allow(IpLookupService).to receive(:new).and_return(instance_double(IpLookupService, perform: geo))

      expect(mail.body.encoded).to include('United States')
      expect(mail.body.encoded).not_to include(', United States')
    end

    it 'escapes request-derived device details so markup cannot be injected' do
      meta[:browser_name] = '<a href="https://evil.test">Chatwoot Mobile</a>'
      expect(mail.body.encoded).not_to include('<a href="https://evil.test">')
      expect(mail.body.encoded).to include('&lt;a href')
    end

    it 'labels itself as a security notification and explains why it was sent' do
      expect(mail.body.encoded).to include('security notification')
      expect(mail.body.encoded).to include('needs to be verified')
    end
  end

  describe 'delivery behavior' do
    it 'delivers through a job that does not log arguments' do
      expect(described_class.delivery_job).to eq(Enterprise::DeviceVerificationDeliveryJob)
      expect(Enterprise::DeviceVerificationDeliveryJob.log_arguments).to be(false)
    end

    it 'never serializes the plaintext code into job arguments' do
      expect do
        described_class.verification_code(user, DeviceVerification.encrypt_code('654321'), meta).deliver_later
      end.to have_enqueued_job(Enterprise::DeviceVerificationDeliveryJob)

      job_args = ActiveJob::Base.queue_adapter.enqueued_jobs.last['arguments'] ||
                 ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args]
      expect(job_args.inspect).not_to include('654321')
    end

    it 're-raises SMTP failures instead of swallowing them' do
      expect do
        described_class.new.send(:handle_smtp_exceptions, Net::SMTPSyntaxError.new('bad recipient'))
      end.to raise_error(Net::SMTPSyntaxError)
    end
  end

  describe '#new_device' do
    let(:mail) { described_class.new_device(user, meta).message }

    it 'notifies about the new device with a reset pointer and security footer' do
      expect(mail.to).to eq(['agent@example.com'])
      expect(mail.subject).to include('new device')
      expect(mail.body.encoded).to include('203.0.113.7')
      expect(mail.body.encoded).to include('reset your password')
      expect(mail.body.encoded).to include('security notification')
    end
  end
end
