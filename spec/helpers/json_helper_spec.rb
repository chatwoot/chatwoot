require 'rails_helper'

RSpec.describe JsonHelper do
  include JsonHelper

  describe '#extract_json_from_code_block' do
    let(:valid_json) do
      {
        'message' => 'ada slot kosong hari ini',
        'response' => 'Hari ini, tanggal 8 Juli 2025, ada slot kosong...',
        'is_handover_human' => false
      }
    end

    it 'parses a raw JSON string' do
      input = <<~JSON
        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false
        }
      JSON
      expect(extract_json_from_code_block(input)).to eq(valid_json)
    end

    it 'parses a markdown code block with ```json' do
      input = <<~MD
        ```json
        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false
        }
        ```
      MD
      expect(extract_json_from_code_block(input)).to eq(valid_json)
    end

    it 'parses a markdown code block with ``` only' do
      input = <<~MD
        ```
        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false
        }
        ```
      MD
      expect(extract_json_from_code_block(input)).to eq(valid_json)
    end

    it 'parses a code block with extra whitespace and newlines' do
      input = <<~MD

        ```json

        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false
        }

        ```
      MD
      expect(extract_json_from_code_block(input)).to eq(valid_json)
    end

    it 'parses a code block with missing closing marker' do
      input = <<~MD
        ```json
        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false
        }
      MD
      expect(extract_json_from_code_block(input)).to eq(valid_json)
    end

    it 'returns nil for invalid JSON' do
      input = <<~MD
        ```json
        {
          "message": "ada slot kosong hari ini",
          "response": "Hari ini, tanggal 8 Juli 2025, ada slot kosong...",
          "is_handover_human": false,
        }
        ```
      MD
      expect(extract_json_from_code_block(input)).to eq(
        {
          'message' => 'Format tidak dikenali',
          'response' => '',
          'is_handover_human' => false
        }
      )
    end
  end
end
