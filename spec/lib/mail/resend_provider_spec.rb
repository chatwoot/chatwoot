require 'rails_helper'

describe Mail::ResendProvider do
  let(:provider) { described_class.new({}) }
  let(:mail) do
    Mail::Message.new(
      headers: {
        from: 'Sender <sender@example.com>',
        to: ['Receiver <receiver@example.com>'],
        subject: 'Test Email'
      },
      body: '<p>This is a test email message.</p>'
    )
  end

  describe '#deliver!' do
    it 'calls Resend with the correct parameters' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(Resend::Emails).to receive(:send)
        .with(
          from: 'Sender <sender@example.com>',
          to: 'Receiver <receiver@example.com>',
          subject: 'Test Email',
          html: '<p>This is a test email message.</p>',
          text: 'This is a test email message.'
        )
        .and_return(response)

      provider.deliver!(mail)

      expect(Resend::Emails).to have_received(:send)
    end

    context 'when response is not successful' do
      it 'raises a DeliveryError with the error message' do
        allow(Resend::Emails).to receive(:send)
          .with(
            from: 'Sender <sender@example.com>',
            to: 'Receiver <receiver@example.com>',
            subject: 'Test Email',
            html: '<p>This is a test email message.</p>',
            text: 'This is a test email message.'
          )
          .and_raise(Resend::Error.new('Service unavailable'))

        expect { provider.deliver!(mail) }
          .to raise_error(described_class::DeliveryError, 'Failed to send email: Service unavailable')
      end
    end

    context 'when an exception occurs during sending' do
      it 'raises a DeliveryError with the exception message' do
        allow(Resend::Emails).to receive(:send).and_raise(StandardError, 'Connection timed out')

        expect { provider.deliver!(mail) }
          .to raise_error(described_class::DeliveryError, 'An error occurred while sending email: Connection timed out')
      end
    end
  end
end
