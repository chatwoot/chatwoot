require 'rails_helper'

# Covers the Instagram comment-reply path of Instagram::SendOnInstagramService.
# Direct-message replies are covered in send_on_instagram_service_spec.rb.
describe Instagram::SendOnInstagramService do
  let!(:account) { create(:account) }
  let!(:channel) { create(:channel_instagram, account: account, instagram_id: 'connected-ig-account-id') }
  let!(:inbox) { create(:inbox, channel: channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let!(:conversation) do
    create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox,
                          additional_attributes: { 'type' => 'instagram_comment', 'instagram_media_id' => 'media-1' })
  end

  before do
    # The incoming comment we are replying to.
    create(:message, message_type: 'incoming', inbox: inbox, account: account, conversation: conversation,
                     source_id: 'comment-1',
                     content_attributes: { 'type' => 'instagram_comment', 'instagram_comment_id' => 'comment-1' })
  end

  describe '#perform on a comment conversation' do
    it 'replies publicly to the latest comment via the Comments API' do
      reply_response = instance_double(
        HTTParty::Response,
        :success? => true,
        :parsed_response => { 'id' => 'reply-comment-id' }
      )
      allow(HTTParty).to receive(:post).and_return(reply_response)

      outgoing = create(:message, message_type: 'outgoing', content: 'Obrigado pelo comentário!',
                                  inbox: inbox, account: account, conversation: conversation)
      described_class.new(message: outgoing).perform

      expect(HTTParty).to have_received(:post)
        .with('https://graph.instagram.com/v22.0/comment-1/replies', hash_including(:body))
      expect(outgoing.reload.source_id).to eq 'reply-comment-id'
    end

    it 'marks the message as failed when the Comments API returns an error' do
      error_body = { 'error' => { 'message' => 'Invalid comment', 'code' => 100 } }
      error_response = instance_double(
        HTTParty::Response,
        :success? => false,
        :parsed_response => error_body
      )
      allow(HTTParty).to receive(:post).and_return(error_response)

      outgoing = create(:message, message_type: 'outgoing', content: 'Obrigado!',
                                  inbox: inbox, account: account, conversation: conversation)
      described_class.new(message: outgoing).perform

      expect(outgoing.reload.status).to eq 'failed'
    end

    it 'marks an attachment-only reply (blank content) as failed without calling the API' do
      allow(HTTParty).to receive(:post)

      outgoing = create(:message, message_type: 'outgoing', content: nil,
                                  inbox: inbox, account: account, conversation: conversation)
      described_class.new(message: outgoing).perform

      expect(HTTParty).not_to have_received(:post)
      expect(outgoing.reload.status).to eq 'failed'
    end

    it 'replies to the latest comment that existed when composed, ignoring older and newer ones' do
      reply_response = instance_double(HTTParty::Response, :success? => true, :parsed_response => { 'id' => 'reply-id' })
      allow(HTTParty).to receive(:post).and_return(reply_response)

      # An older comment in the same grouped conversation (must not win over comment-1).
      create(:message, message_type: 'incoming', inbox: inbox, account: account, conversation: conversation,
                       source_id: 'comment-0', created_at: 2.minutes.ago,
                       content_attributes: { 'type' => 'instagram_comment', 'instagram_comment_id' => 'comment-0' })

      outgoing = create(:message, message_type: 'outgoing', content: 'Resposta',
                                  inbox: inbox, account: account, conversation: conversation)
      # A newer comment arrives while the reply sits in the SendReplyJob queue.
      create(:message, message_type: 'incoming', inbox: inbox, account: account, conversation: conversation,
                       source_id: 'comment-2', created_at: outgoing.created_at + 1.minute,
                       content_attributes: { 'type' => 'instagram_comment', 'instagram_comment_id' => 'comment-2' })

      described_class.new(message: outgoing).perform

      expect(HTTParty).to have_received(:post).with('https://graph.instagram.com/v22.0/comment-1/replies', hash_including(:body))
    end
  end
end
