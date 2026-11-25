require 'rails_helper'

# Regression: removing a reaction never reached WhatsApp. Chatwoot models "one reaction
# per (message, sender)" by reusing the row and marking it deleted, and the guard that
# keeps a deleted message off the channel (#353) could not tell the two apart: the emoji
# disappeared from the dashboard and stayed on the contact's phone forever.
RSpec.describe 'WhatsApp reaction removal', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_whatsapp, provider: 'baileys', account: account, validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+551187654321', identifier: nil) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '551187654321') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  let(:send_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}/send-message" }
  let!(:send_stub) do
    stub_request(:post, send_url).to_return(
      status: 200,
      body: { data: { key: { id: 'wa_reaction_1' }, messageTimestamp: 1_700_000_000 } }.to_json,
      headers: { 'content-type' => 'application/json' }
    )
  end

  let!(:target) do
    create(:message, message_type: :incoming, content: 'oi', conversation: conversation,
                     account: account, inbox: inbox, source_id: 'wa_target_1')
  end

  before { create(:inbox_member, inbox: inbox, user: agent) }

  def toggle_reaction(emoji)
    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{target.id}/reactions",
         params: { emoji: emoji }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    # Only the send: the surrounding jobs include avatar fetches, which would go to the
    # network for something this spec is not about.
    perform_enqueued_jobs(only: SendReplyJob)
  end

  def reaction_sent_with(emoji)
    a_request(:post, send_url).with { |request| JSON.parse(request.body).dig('messageContent', 'react', 'text') == emoji }
  end

  it 'sends the empty emoji that clears the reaction on the phone' do
    toggle_reaction('👍')
    toggle_reaction('👍')

    expect(send_stub).to have_been_requested.twice
    expect(reaction_sent_with('👍')).to have_been_made
    expect(reaction_sent_with('')).to have_been_made
  end

  it 'leaves the reaction row deleted, which is how the dashboard hides it' do
    toggle_reaction('👍')
    toggle_reaction('👍')

    reaction = conversation.reload.messages.detect { |message| message.content_attributes['is_reaction'] }
    expect(reaction).to be_deleted
    expect(reaction).to be_removed_reaction
  end

  # The row was deleted from the start, and the empty emoji is what clears the reaction.
  # Revoking on top of it would ask the provider to delete the reaction message itself.
  it 'does not also revoke the reaction message' do
    toggle_reaction('👍')
    toggle_reaction('👍')

    expect(Messages::DeleteOnChannelJob).not_to have_been_enqueued
  end

  # A message the agent deleted still must not reach the contact: the guard this change
  # narrows is the one that stops the "deleted" placeholder from being delivered.
  it 'still keeps a deleted message off the channel' do
    message = create(:message, message_type: :outgoing, content: 'segredo', conversation: conversation,
                               account: account, inbox: inbox, source_id: nil)
    message.update!(content_attributes: message.content_attributes.merge('deleted' => true))

    SendReplyJob.perform_now(message.id)

    expect(send_stub).not_to have_been_requested
  end
end
