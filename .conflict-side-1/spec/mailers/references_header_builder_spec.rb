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

    context 'when no message is found with the in_reply_to_message_id' do
      it 'returns only the in_reply_to message ID' do
        result = build_references_header(conversation, in_reply_to_message_id)
        expect(result).to eq('<reply-to-123@example.com>')
      end
    end

    context 'when a message is found with matching source_id' do
      context 'with stored References' do
        let(:original_message) do
          create(:message, conversation: conversation, account: account,
                           source_id: '<reply-to-123@example.com>',
                           content_attributes: {
                             'email' => {
                               'references' => ['<thread-001@example.com>', '<thread-002@example.com>']
                             }
                           })
        end

        before do
          original_message
        end

        it 'includes stored References plus in_reply_to' do
          result = build_references_header(conversation, in_reply_to_message_id)
          expect(result).to eq("<thread-001@example.com>\r\n <thread-002@example.com>\r\n <reply-to-123@example.com>")
        end

        it 'removes duplicates while preserving order' do
          # If in_reply_to is already in the References, it should appear only once at the end
          original_message.content_attributes['email']['references'] = ['<thread-001@example.com>', '<reply-to-123@example.com>']
          original_message.save!

          result = build_references_header(conversation, in_reply_to_message_id)
          message_ids = result.split("\r\n ").map(&:strip)
          expect(message_ids).to eq(['<thread-001@example.com>', '<reply-to-123@example.com>'])
        end
      end

      context 'without stored References' do
        let(:original_message) do
          create(:message, conversation: conversation, account: account,
                           source_id: 'reply-to-123@example.com', # without angle brackets
                           content_attributes: { 'email' => {} })
        end

        before do
          original_message
        end

        it 'returns only the in_reply_to message ID (no rebuild)' do
          result = build_references_header(conversation, in_reply_to_message_id)
          expect(result).to eq('<reply-to-123@example.com>')
        end
      end
    end

    context 'with folding multiple References' do
      let(:original_message) do
        create(:message, conversation: conversation, account: account,
                         source_id: '<reply-to-123@example.com>',
                         content_attributes: {
                           'email' => {
                             'references' => ['<msg-001@example.com>', '<msg-002@example.com>', '<msg-003@example.com>']
                           }
                         })
      end

      before do
        original_message
      end

      it 'folds the header with CRLF between message IDs' do
        result = build_references_header(conversation, in_reply_to_message_id)

        expect(result).to include("\r\n")
        lines = result.split("\r\n")

        # First line has no leading space, continuation lines do
        expect(lines.first).not_to start_with(' ')
        expect(lines[1..]).to all(start_with(' '))
      end
    end

    context 'with source_id in different formats' do
      it 'finds message with source_id without angle brackets' do
        create(:message, conversation: conversation, account: account,
                         source_id: 'test-123@example.com',
                         content_attributes: {
                           'email' => {
                             'references' => ['<ref-1@example.com>']
                           }
                         })

        result = build_references_header(conversation, '<test-123@example.com>')
        expect(result).to eq("<ref-1@example.com>\r\n <test-123@example.com>")
      end

      it 'finds message with source_id with angle brackets' do
        create(:message, conversation: conversation, account: account,
                         source_id: '<test-456@example.com>',
                         content_attributes: {
                           'email' => {
                             'references' => ['<ref-2@example.com>']
                           }
                         })

        result = build_references_header(conversation, 'test-456@example.com')
        expect(result).to eq("<ref-2@example.com>\r\n test-456@example.com")
      end
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
