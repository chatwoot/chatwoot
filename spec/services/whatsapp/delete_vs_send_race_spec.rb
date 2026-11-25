require 'rails_helper'

# Regression: deleting a message while it is still on its way to the provider used to leave it alive
# on WhatsApp and deleted in Chatwoot — the DELETE endpoint found no `source_id` to revoke and the
# send job went on to deliver the "deleted" placeholder to the contact.
RSpec.describe 'WhatsApp delete vs send race', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_whatsapp, provider: 'baileys', account: account, validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+551187654321', identifier: nil) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '551187654321') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  let(:send_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}/send-message" }
  let(:delete_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}/messages" }
  let(:send_success_body) { { data: { key: { id: 'wa_msg_123' }, messageTimestamp: 1_700_000_000 } }.to_json }

  let!(:delete_stub) { stub_request(:delete, delete_url).to_return(status: 200, body: '{}') }
  let!(:send_stub) do
    stub_request(:post, send_url).to_return(status: 200, body: send_success_body, headers: { 'content-type' => 'application/json' })
  end

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    # keeps the 24h messaging window open
    create(:message, message_type: :incoming, content: 'oi', conversation: conversation, account: account, inbox: inbox)
  end

  def delete_message_via_api(message)
    delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
           headers: agent.create_new_auth_token,
           as: :json
  end

  context 'when the agent deletes before SendReplyJob runs' do
    it 'aborts the send instead of delivering the deleted placeholder' do
      message = create(:message, message_type: :outgoing, content: 'segredo que não era pra vazar',
                                 conversation: conversation, account: account, inbox: inbox, source_id: nil)
      expect(SendReplyJob).to have_been_enqueued.with(message.id)

      delete_message_via_api(message)
      expect(response).to have_http_status(:success)

      SendReplyJob.perform_now(message.id)

      expect(send_stub).not_to have_been_requested
      expect(delete_stub).not_to have_been_requested
      expect(message.reload).to be_deleted
      expect(message.source_id).to be_nil
    end
  end

  context 'when the agent deletes while the job waits on the baileys channel lock' do
    it 're-checks under the lock and aborts the send' do
      message = create(:message, message_type: :outgoing, content: 'esperando o lock',
                                 conversation: conversation, account: account, inbox: inbox, source_id: nil)
      service = Whatsapp::SendOnWhatsappService.new(message: message)
      # another request deletes it while this job sits in the queue, so `message` here is stale
      Message.find(message.id).update!(content: 'This message was deleted', content_attributes: { deleted: true })

      service.perform

      expect(send_stub).not_to have_been_requested
      expect(message.reload).to be_deleted
    end
  end

  context 'when the agent deletes while the send is in flight on the provider' do
    it 'keeps the message deleted and revokes it on the provider once the source_id lands' do
      message = create(:message, message_type: :outgoing, content: 'mensagem em voo',
                                 conversation: conversation, account: account, inbox: inbox, source_id: nil)

      stub_request(:post, send_url).to_return do |_req|
        # the agent hits "Delete" while the provider is still processing the send
        delete_message_via_api(message)
        { status: 200, body: send_success_body, headers: { 'content-type' => 'application/json' } }
      end

      perform_enqueued_jobs(only: Messages::DeleteOnChannelJob) do
        Whatsapp::SendOnWhatsappService.new(message: message).perform
      end

      message.reload
      expect(message).to be_deleted
      expect(message.content).to eq('This message was deleted')
      expect(message.source_id).to eq('wa_msg_123')
      # exactly once: the DELETE endpoint saw no source_id under the lock and left the revocation to us
      expect(delete_stub).to have_been_requested.once
    end
  end

  context 'when the message carries an attachment' do
    it 'aborts the send that was scheduled with the 2s attachment delay' do
      message = build(:message, message_type: :outgoing, content: 'legenda da foto',
                                conversation: conversation, account: account, inbox: inbox, source_id: nil)
      attachment = message.attachments.new(account_id: account.id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!
      expect(SendReplyJob).to have_been_enqueued.with(message.id).at(a_value_within(5.seconds).of(2.seconds.from_now))

      delete_message_via_api(message)
      expect(response).to have_http_status(:success)
      expect(message.reload.attachments).to be_empty

      SendReplyJob.perform_now(message.id)

      expect(send_stub).not_to have_been_requested
      expect(delete_stub).not_to have_been_requested
    end
  end
end
