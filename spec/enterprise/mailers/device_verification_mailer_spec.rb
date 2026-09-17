require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe Enterprise::DeviceVerificationMailer do
  include_context 'with smtp config'

  let(:user) { create(:user, email: 'agent@example.com') }
  let(:meta) { { ip: '203.0.113.7', browser_name: 'Chrome', platform_name: 'macOS' } }

  describe '#verification_code' do
    let(:mail) { described_class.verification_code(user, DeviceVerification.encrypt_code('123456'), meta).deliver_now }

    it 'sends the code to the user with device details' do
      expect(mail.to).to eq(['agent@example.com'])
      expect(mail.subject).to include('verification code')
      expect(mail.body.encoded).to include('123456')
      expect(mail.body.encoded).to include('203.0.113.7')
      expect(mail.body.encoded).to include('Chrome')
      expect(mail.body.encoded).to include('10 minutes')
    end

    it 'tells the user where to type the code' do
      expect(mail.body.encoded).to include('enter it in the code field on the verification screen')
    end

    it 'includes a password reset pointer for unrecognized sign-ins' do
      expect(mail.body.encoded).to include('reset your password')
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
    let(:mail) { described_class.new_device(user, meta).deliver_now }

    it 'notifies about the new device with a reset pointer' do
      expect(mail.to).to eq(['agent@example.com'])
      expect(mail.subject).to include('new device')
      expect(mail.body.encoded).to include('203.0.113.7')
      expect(mail.body.encoded).to include('reset your password')
    end
  end
end
