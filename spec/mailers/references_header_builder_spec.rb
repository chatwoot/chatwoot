# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReferencesHeaderBuilder do
  include described_class

  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:inbox) { create(:inbox, channel: email_channel, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#build_references_header' do
    let(:in_reply_to_message_id) { '<reply-to-123@example.com>' }

    context 'with an empty conversation' do
      it 'returns only the in_reply_to message ID' do
        result = build_references_header(conversation, in_reply_to_message_id)
        expect(result).to eq('<reply-to-123@example.com>')
      end
    end

    context 'with a conversation containing multiple messages' do
      it 'includes all message IDs in chronological order' do
        create(:message, conversation: conversation, account: account, source_id: '<msg-001@example.com>', created_at: 3.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: 'msg-002@example.com', created_at: 2.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: '<msg-003@example.com>', created_at: 1.minute.ago)

        result = build_references_header(conversation, in_reply_to_message_id)

        expect(result).to include('<msg-001@example.com>')
        expect(result).to include('<msg-002@example.com>')
        expect(result).to include('<msg-003@example.com>')
        expect(result).to include('<reply-to-123@example.com>')
      end

      it 'maintains chronological order with in_reply_to as last element' do
        create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 2.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: 'msg-002@example.com', created_at: 1.minute.ago)

        result = build_references_header(conversation, in_reply_to_message_id)
        message_ids = result.split(/\s+/)

        expect(message_ids).to eq(['<msg-001@example.com>', '<msg-002@example.com>', '<reply-to-123@example.com>'])
      end

      it 'removes duplicates while preserving order' do
        create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 2.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 1.minute.ago) # Duplicate

        result = build_references_header(conversation, in_reply_to_message_id)
        message_ids = result.split(/\s+/)

        expect(message_ids.count('<msg-001@example.com>')).to eq(1)
      end

      it 'handles message IDs without angle brackets' do
        create(:message, conversation: conversation, account: account, source_id: 'no-brackets@example.com', created_at: 1.minute.ago)

        result = build_references_header(conversation, in_reply_to_message_id)
        expect(result).to include('<no-brackets@example.com>')
      end
    end

    context 'with multiple messages' do
      it 'folds the header with CRLF between message IDs' do
        create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 3.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: 'msg-002@example.com', created_at: 2.minutes.ago)
        create(:message, conversation: conversation, account: account, source_id: 'msg-003@example.com', created_at: 1.minute.ago)

        result = build_references_header(conversation, in_reply_to_message_id)

        expect(result).to include("\r\n")
        lines = result.split("\r\n")

        # First line has no leading space, continuation lines do
        expect(lines.first).not_to start_with(' ')
        lines[1..].each do |line|
          expect(line).to start_with(' ')
        end
      end
    end
  end

  describe '#collect_chronological_message_ids' do
    it 'collects message IDs in chronological order' do
      create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 3.minutes.ago)
      create(:message, conversation: conversation, account: account, source_id: 'msg-002@example.com', created_at: 2.minutes.ago)
      create(:message, conversation: conversation, account: account, source_id: 'msg-003@example.com', created_at: 1.minute.ago)

      result = collect_chronological_message_ids(conversation)

      expect(result).to eq(['<msg-001@example.com>', '<msg-002@example.com>', '<msg-003@example.com>'])
    end

    it 'only includes messages with source_id' do
      create(:message, conversation: conversation, account: account, source_id: 'msg-001@example.com', created_at: 2.minutes.ago)
      create(:message, conversation: conversation, account: account, created_at: 1.minute.ago) # No source_id

      result = collect_chronological_message_ids(conversation)

      expect(result).to eq(['<msg-001@example.com>'])
    end

    it 'formats message IDs with angle brackets' do
      create(:message, conversation: conversation, account: account, source_id: 'no-brackets@example.com', created_at: 1.minute.ago)

      result = collect_chronological_message_ids(conversation)

      expect(result).to eq(['<no-brackets@example.com>'])
    end
  end

  describe '#fold_references_header' do
    it 'returns single message ID without folding' do
      single_array = ['<msg1@example.com>']
      result = fold_references_header(single_array)

      expect(result).to eq('<msg1@example.com>')
      expect(result).not_to include("\r\n")
    end

    it 'folds multiple message IDs with CRLF + space' do
      multiple_array = ['<msg1@example.com>', '<msg2@example.com>', '<msg3@example.com>']
      result = fold_references_header(multiple_array)

      expect(result).to eq("<msg1@example.com>\r\n <msg2@example.com>\r\n <msg3@example.com>")
    end

    it 'ensures RFC 5322 compliance with continuation line spacing' do
      multiple_array = ['<msg1@example.com>', '<msg2@example.com>']
      result = fold_references_header(multiple_array)
      lines = result.split("\r\n")

      # First line has no leading space (not a continuation line)
      expect(lines.first).to eq('<msg1@example.com>')
      expect(lines.first).not_to start_with(' ')

      # Second line starts with space (continuation line)
      expect(lines[1]).to eq(' <msg2@example.com>')
      expect(lines[1]).to start_with(' ')
    end

    it 'handles empty array' do
      result = fold_references_header([])
      expect(result).to eq('')
    end
  end
end