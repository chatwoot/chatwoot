require 'rails_helper'

describe Whatsapp::FlowResponseFormatter do
  let(:payload) do
    {
      'flow_token' => 'cw_1_2',
      'nombre' => 'Diego',
      'direccion' => 'Av. Amazonas 123',
      'password' => 'secret'
    }
  end

  describe '.format_details' do
    it 'hides system and sensitive keys' do
      details = described_class.format_details(payload)
      expect(details).to include('Nombre: Diego')
      expect(details).to include('Direccion: Av. Amazonas 123')
      expect(details).not_to include('cw_1_2')
      expect(details).not_to include('secret')
    end
  end

  describe '.format_confirmation' do
    it 'builds a customer confirmation message' do
      text = described_class.format_confirmation(payload)
      expect(text).to include('Recibimos tu información')
      expect(text).to include('Nombre: Diego')
      expect(text).to include('Si algo está mal')
    end
  end

  describe '.parse_response_json' do
    it 'parses nfm_reply response_json' do
      message = {
        interactive: {
          type: 'nfm_reply',
          nfm_reply: {
            response_json: payload.to_json
          }
        }
      }

      expect(described_class.parse_response_json(message)).to eq(payload)
    end
  end
end
