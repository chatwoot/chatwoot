require 'rails_helper'

RSpec.describe Jusmonitoria::MovementNotificationMailer, type: :mailer do
  let(:account) { create(:account) }

  it 'renders the JusMonitorIA movement notification email payload' do
    mail = described_class.with(
      account: account,
      to: 'advogada@firm.test',
      subject: 'Novas movimentações no processo 0001',
      html_content: '<p>Movimentação nova</p>',
      text_content: 'Movimentação nova'
    ).notification

    expect(mail.to).to eq(['advogada@firm.test'])
    expect(mail.subject).to eq('Novas movimentações no processo 0001')
    expect(mail.body.encoded).to include('Movimenta')
  end
end
