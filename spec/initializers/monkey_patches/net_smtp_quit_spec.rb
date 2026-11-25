require 'rails_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- the subject is the patch, which lives in
# config/initializers/monkey_patches/net_smtp_quit.rb; mirroring that path is the point.
describe Net::SMTP do
  let(:smtp) { described_class.new('smtp.example.com') }

  # Guarding the class, not just the behaviour: Email::SendOnEmailService retries on
  # Net::SMTPServerBusy because it reads as "the server did not take the message". A 4xx
  # answered to QUIT raises the same class after the message was accepted, so without
  # this patch the retry sends the customer a second copy.
  it 'swallows a 4xx answered to QUIT, which arrives after the message was accepted' do
    allow(smtp).to receive(:getok).with('QUIT').and_raise(
      Net::SMTPServerBusy, '421 4.7.0 Try again later'
    )

    expect { smtp.quit }.not_to raise_error
  end

  # Net::ReadTimeout and Net::WriteTimeout descend from Timeout::Error -> RuntimeError, so
  # they match none of the SMTP/IO/syscall/SSL entries in the rescue. A server that takes
  # the DATA and then stalls on QUIT is the ordinary way to reach this.
  [Net::ReadTimeout, Net::WriteTimeout].each do |error_class|
    it "swallows #{error_class} on QUIT" do
      allow(smtp).to receive(:getok).with('QUIT').and_raise(error_class)

      expect { smtp.quit }.not_to raise_error
    end
  end

  it 'swallows a dropped connection on QUIT' do
    allow(smtp).to receive(:getok).with('QUIT').and_raise(Errno::ECONNRESET)

    expect { smtp.quit }.not_to raise_error
  end

  it 'still performs the QUIT when the server answers normally' do
    allow(smtp).to receive(:getok).with('QUIT').and_return(:ok)

    smtp.quit

    expect(smtp).to have_received(:getok).with('QUIT')
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
