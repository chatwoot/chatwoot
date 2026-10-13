require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'WhatsApp interactive mobile handoff contract' do
  let(:handoff) do
    JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/mobile_handoff.json').read)
  end
  let(:outgoing_messages) { handoff.fetch('outgoing_messages') }
  let(:inbound_selections) { handoff.fetch('inbound_selections') }
  let(:evidence_matrix) do
    Rails.root.join('spec/fixtures/whatsapp_interactive_messages/README.md').read
  end
  let(:attached_file_class) do
    Struct.new(:blob, :filename) do
      def attached?
        true
      end
    end
  end
  let(:expected_attachment_envelopes) do
    {
      501 => {
        'id' => 501, 'message_id' => 2001, 'file_type' => 'image', 'account_id' => 71, 'extension' => 'png',
        'content_type' => 'image/png',
        'data_url' => 'https://example.test/rails/active_storage/blobs/button-header.png',
        'thumb_url' => 'https://example.test/rails/active_storage/representations/button-header.png',
        'file_size' => 2048, 'width' => 640, 'height' => 360
      },
      502 => {
        'id' => 502, 'message_id' => 2004, 'file_type' => 'image', 'account_id' => 71, 'extension' => 'jpg',
        'content_type' => 'image/jpeg',
        'data_url' => 'https://example.test/rails/active_storage/blobs/mountain.jpg',
        'thumb_url' => 'https://example.test/rails/active_storage/representations/mountain.jpg',
        'file_size' => 4096, 'width' => 800, 'height' => 800
      },
      503 => {
        'id' => 503, 'message_id' => 2004, 'file_type' => 'image', 'account_id' => 71, 'extension' => 'jpg',
        'content_type' => 'image/jpeg',
        'data_url' => 'https://example.test/rails/active_storage/blobs/beach.jpg',
        'thumb_url' => 'https://example.test/rails/active_storage/representations/beach.jpg',
        'file_size' => 4096, 'width' => 800, 'height' => 800
      },
      504 => {
        'id' => 504, 'message_id' => 2005, 'file_type' => 'image', 'account_id' => 71, 'extension' => 'jpg',
        'content_type' => 'image/jpeg',
        'data_url' => 'https://example.test/rails/active_storage/blobs/quick-mountain.jpg',
        'thumb_url' => 'https://example.test/rails/active_storage/representations/quick-mountain.jpg',
        'file_size' => 4096, 'width' => 800, 'height' => 800
      },
      505 => {
        'id' => 505, 'message_id' => 2005, 'file_type' => 'image', 'account_id' => 71, 'extension' => 'jpg',
        'content_type' => 'image/jpeg',
        'data_url' => 'https://example.test/rails/active_storage/blobs/quick-beach.jpg',
        'thumb_url' => 'https://example.test/rails/active_storage/representations/quick-beach.jpg',
        'file_size' => 4096, 'width' => 800, 'height' => 800
      }
    }
  end

  let(:expected_sender_envelopes) do
    {
      outgoing: {
        'id' => 81, 'name' => 'Fixture Agent', 'available_name' => 'Fixture Agent', 'avatar_url' => nil,
        'type' => 'user', 'availability_status' => 'online', 'thumbnail' => nil
      },
      incoming: {
        'additional_attributes' => {}, 'custom_attributes' => {}, 'email' => nil, 'id' => 91, 'identifier' => nil,
        'name' => 'Fixture Contact', 'phone_number' => nil, 'thumbnail' => nil, 'blocked' => false, 'type' => 'contact'
      }
    }
  end

  let(:media_references) do
    lambda do |snapshot|
      references = []
      header = snapshot['header']
      references << [header['type'], header['attachment_id']] if header&.key?('attachment_id')
      Array(snapshot.dig('action', 'cards')).each do |card|
        card_header = card['header']
        references << [card_header['type'], card_header['attachment_id']] if card_header&.key?('attachment_id')
      end
      references
    end
  end

  let(:attachment_contract_errors) do
    lambda do |message|
      snapshot = message.dig('content_attributes', 'whatsapp_interactive')
      references = media_references.call(snapshot)
      attachments = message.fetch('attachments', [])
      errors = []
      errors << 'media references must be unique' unless references.map(&:last).uniq.length == references.length
      errors << 'attachment records must be unique' unless attachments.pluck('id').uniq.length == attachments.length

      references.each do |header_type, attachment_id|
        matches = attachments.select { |attachment| attachment['id'] == attachment_id }
        expected_file_type = header_type == 'document' ? 'file' : header_type
        errors << "attachment #{attachment_id} must resolve exactly once" unless matches.one?
        errors << "attachment #{attachment_id} has the wrong file type" unless matches.one? && matches.first['file_type'] == expected_file_type
      end

      errors << 'attachments and media references must have the same IDs' unless attachments.pluck('id').sort == references.map(&:last).sort
      errors
    end
  end

  let(:snapshot_options) do
    lambda do |snapshot, reply_type|
      case "#{snapshot['type']}:#{reply_type}"
      when 'button:button_reply'
        Array(snapshot.dig('action', 'buttons')).map { |option| [option, nil] }
      when 'list:list_reply'
        Array(snapshot.dig('action', 'sections')).flat_map do |section|
          Array(section['rows']).map { |option| [option, nil] }
        end
      when 'carousel:button_reply'
        Array(snapshot.dig('action', 'cards')).flat_map do |card|
          Array(card.dig('action', 'buttons')).map { |option| [option, card['card_index']] }
        end
      else
        []
      end
    end
  end

  it 'uses the public snake-case message envelope for five outgoing forms' do
    expect(handoff.fetch('schema_version')).to eq(1)
    expect(outgoing_messages.keys).to contain_exactly('button', 'list', 'cta_url', 'carousel_url', 'carousel_quick_reply')

    outgoing_messages.each_value do |message|
      expected_keys = %w[
        id content inbox_id conversation_id message_type content_type status content_attributes
        created_at private source_id sender
      ]
      expected_keys << 'attachments' if message.key?('attachments')
      expect(message.keys).to match_array(expected_keys)
      expect(message).to include('message_type' => 1, 'content_type' => 'text', 'private' => false)
      expect(message['sender']).to eq(expected_sender_envelopes.fetch(:outgoing))
      expect(message['content']).to eq(message.dig('content_attributes', 'whatsapp_interactive', 'body', 'text'))
    end

    walk = lambda do |value|
      case value
      when Hash
        value.each do |key, nested_value|
          expect(key).to match(/\A[a-z][a-z0-9_]*\z/)
          walk.call(nested_value)
        end
      when Array
        value.each { |nested_value| walk.call(nested_value) }
      end
    end
    walk.call(handoff)
  end

  it 'keeps every outgoing snapshot valid against the authoritative registry' do
    outgoing_messages.each_value do |message|
      snapshot = message.dig('content_attributes', 'whatsapp_interactive')
      attachment_doubles = message.fetch('attachments', []).map do |attachment|
        file = attached_file_class.new(
          instance_double(ActiveStorage::Blob, content_type: attachment.fetch('content_type')),
          attachment.fetch('data_url').split('/').last
        )
        instance_double(
          Attachment,
          id: attachment.fetch('id'),
          file_type: attachment.fetch('file_type'),
          file: file,
          download_url: attachment.fetch('data_url')
        )
      end

      arguments = snapshot['type'] == 'carousel' ? { attachments: attachment_doubles } : { attachment: attachment_doubles.first }
      expect { Whatsapp::InteractiveMessages::Registry.provider_payload(snapshot, **arguments) }.not_to raise_error
      expect(snapshot.fetch('source')).to match('preset_id' => be_positive)
    end
  end

  it 'rejects a malformed stored snapshot through the registry' do
    malformed = outgoing_messages.fetch('button').dig('content_attributes', 'whatsapp_interactive').deep_dup
    malformed['schema_version'] = 2

    expect { Whatsapp::InteractiveMessages::Registry.provider_payload(malformed) }
      .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /schema_version/)
  end

  it 'joins every media reference to exactly one compatible serialized attachment without provider media IDs' do
    outgoing_messages.each_value do |message|
      expect(attachment_contract_errors.call(message)).to be_empty
      expect(message.to_json).not_to include('media_id', 'provider_media_id')
      message.fetch('attachments', []).each do |attachment|
        expect(attachment).to eq(expected_attachment_envelopes.fetch(attachment.fetch('id')))
        expect(attachment.fetch('message_id')).to eq(message.fetch('id'))
      end
    end
    expect(outgoing_messages.values.flat_map { |message| message.fetch('attachments', []) }.pluck('id'))
      .to match_array(expected_attachment_envelopes.keys)
  end

  it 'rejects missing, duplicate, and wrong-type attachment correlations' do
    missing = outgoing_messages.fetch('button').deep_dup
    missing['attachments'].clear

    duplicate = outgoing_messages.fetch('carousel_url').deep_dup
    duplicate.dig('content_attributes', 'whatsapp_interactive', 'action', 'cards', 1, 'header')['attachment_id'] = 502

    wrong_type = outgoing_messages.fetch('button').deep_dup
    wrong_type.dig('attachments', 0)['file_type'] = 'video'

    expect(attachment_contract_errors.call(missing)).to include(/resolve exactly once/)
    expect(attachment_contract_errors.call(duplicate)).to include('media references must be unique')
    expect(attachment_contract_errors.call(wrong_type)).to include(/wrong file type/)
  end

  it 'preserves the serialized sender identity for outgoing and inbound messages' do
    expect(outgoing_messages.values.pluck('sender')).to all(eq(expected_sender_envelopes.fetch(:outgoing)))
    expect(inbound_selections.values.pluck('sender')).to all(eq(expected_sender_envelopes.fetch(:incoming)))
  end

  it 'preserves evidenced button, list, and carousel reply correlation' do
    expect(inbound_selections.keys).to contain_exactly('button', 'list', 'carousel', 'unknown_delivery_id')

    inbound_selections.except('unknown_delivery_id').each_value do |message|
      reply = message.dig('content_attributes', 'whatsapp_interactive_reply')
      outgoing = outgoing_messages.values.find { |candidate| candidate['id'] == reply['originating_message_id'] }
      expect(outgoing).to be_present
      expect(message).to include(
        'content' => reply['title'],
        'content_attributes' => hash_including(
          'in_reply_to' => outgoing['id'],
          'in_reply_to_external_id' => outgoing['source_id'],
          'whatsapp_interactive_reply' => hash_including('context_id' => outgoing['source_id'])
        )
      )

      snapshot = outgoing.dig('content_attributes', 'whatsapp_interactive')
      option, card_index = snapshot_options.call(snapshot, reply['type']).find do |candidate, _index|
        candidate['delivery_id'] == reply['delivery_id']
      end
      expect(option).to be_present
      expect(reply['preset_option_id']).to eq(option['preset_option_id'])
      expect(reply['card_index']).to eq(card_index)
      expect(reply).not_to have_key('card_index') if card_index.nil?
    end
  end

  it 'keeps an unknown provider selection readable without inventing stable or card identity' do
    message = inbound_selections.fetch('unknown_delivery_id')
    reply = message.dig('content_attributes', 'whatsapp_interactive_reply')
    outgoing = outgoing_messages.values.find { |candidate| candidate['id'] == reply['originating_message_id'] }
    snapshot = outgoing.dig('content_attributes', 'whatsapp_interactive')

    expect(message['content']).to eq('A provider-only choice')
    expect(reply).to include(
      'delivery_id' => 'reply_unknown_provider_value',
      'title' => 'A provider-only choice',
      'context_id' => outgoing['source_id'],
      'originating_message_id' => outgoing['id']
    )
    expect(snapshot_options.call(snapshot, reply['type']).map { |option, _index| option['delivery_id'] })
      .not_to include(reply['delivery_id'])
    expect(reply).not_to have_key('preset_option_id')
    expect(reply).not_to have_key('card_index')
  end

  it 'keeps live recipient and mobile rendering evidence explicitly pending' do
    expect(evidence_matrix).to include(
      'All evidence below is fixture- or mock-backed automated evidence and does not contact Meta.',
      'SCN-16/AC-18 is intentionally pending for mobile Stories 24–27',
      'SCN-20/AC-26 is release evidence, not product state.',
      'pending until explicitly authorized live verification'
    )
  end

  it 'names every automated evidence entry with an executable repository-root spec path' do
    evidence_rows = evidence_matrix.lines.grep(/^\| SCN-/)
    expected_scenarios = (1..19).filter_map { |number| format('SCN-%02d', number) unless number == 16 }
    documented_scenarios = evidence_rows.map { |row| row.match(/\A\| (SCN-\d{2})/)[1] }
    expect(documented_scenarios).to match_array(expected_scenarios)

    evidence_rows.each do |row|
      evidence = row.split('|').map(&:strip).fetch(2)
      paths = evidence.scan(/`([^`]+)`/).flatten
      expect(paths).not_to be_empty
      expect(evidence.gsub(/`[^`]+`/, '').delete('; ')).to be_empty
      paths.each do |path|
        expect(path).to match(%r{\A(?:spec/.+_spec\.rb|app/javascript/.+\.spec\.js)\z})
        expect(Rails.root.join(path)).to exist
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
