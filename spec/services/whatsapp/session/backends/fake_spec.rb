require 'rails_helper'

RSpec.describe Whatsapp::Session::Backends::Fake do
  subject(:backend) { described_class.new(channel) }

  let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }

  it_behaves_like 'a whatsapp session backend'

  it 'records every command it is given' do
    backend.send_message(
      Whatsapp::Session::Model::Commands::MessageSend.new(
        message_id: '3EB0AAAA', to: Whatsapp::Session::Model::Address.phone('5541999990000'),
        content: Whatsapp::Session::Model::Content::Text.new(body: 'oi')
      )
    )

    expect(backend.commands_of('message.send').size).to eq(1)
    expect(backend.last_command.content.body).to eq('oi')
  end

  it 'emits events with a monotonic cursor' do
    first = backend.emit(Whatsapp::Session::Model::Events::PairingQr.new(png_data_url: described_class::QR_DATA_URL))
    second = backend.emit(Whatsapp::Session::Model::Events::SessionState.new(state: 'open'))

    expect(second).to be_newer_than(first.cursor)
    expect(second.type).to eq('session.state')
  end
end
