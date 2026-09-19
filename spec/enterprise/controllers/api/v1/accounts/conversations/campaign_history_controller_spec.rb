require 'rails_helper'

RSpec.describe 'Conversation campaign history API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, created_at: sent_at - 1.day) }
  let(:campaign) { create(:campaign, account: account, inbox: inbox) }
  let(:sent_at) { 1.day.ago.change(usec: 0) }
  let(:recipient) do
    CampaignRecipient.create!(account: account, campaign: campaign, inbox: inbox, contact: conversation.contact,
                              message_content: 'Your member offer', source_id: 'wamid.history', status: :read,
                              sent_at: sent_at, delivered_at: sent_at + 1.minute, read_at: sent_at + 2.minutes)
  end
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/campaign_history" }
  let(:headers) { administrator.create_new_auth_token }

  before { account.enable_features!(:whatsapp_campaign) }

  it 'returns saved content, campaign display ID, delivery timestamps and the first message ID without creating records' do
    recipient
    campaign.update!(display_id: 1234)
    message = create(:message, account: account, inbox: inbox, conversation: conversation)
    headers

    expect { get url, headers: headers }.to not_change(Message, :count).and not_change(Conversation, :count)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      'payload' => [{ 'id' => recipient.id, 'campaign' => { 'id' => 1234, 'title' => campaign.title },
                      'message_content' => 'Your member offer', 'source_id' => 'wamid.history', 'status' => 'read',
                      'sent_at' => sent_at.to_i, 'delivered_at' => (sent_at + 1.minute).to_i,
                      'read_at' => (sent_at + 2.minutes).to_i, 'failed_at' => nil }],
      'meta' => { 'next_before' => nil, 'first_message_id' => message.id }
    )
  end

  it 'returns empty history and no first message for a conversation without messages' do
    get url, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('payload' => [], 'meta' => { 'next_before' => nil, 'first_message_id' => nil })
  end

  it 'allows an agent who can view the conversation' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, inbox: inbox, user: agent)
    recipient

    get url, headers: agent.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload'].pluck('id')).to eq([recipient.id])
  end

  it 'rejects unauthenticated requests' do
    get url
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects an agent without conversation access' do
    agent = create(:user, account: account, role: :agent)
    get url, headers: agent.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects users from another account' do
    outsider = create(:user, account: create(:account), role: :administrator)
    get url, headers: outsider.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
  end

  it 'requires the WhatsApp campaigns feature' do
    account.disable_features!(:whatsapp_campaign)
    get url, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects non-WhatsApp conversations' do
    other_conversation = create(:conversation, account: account)
    get "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.display_id}/campaign_history", headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  context 'with recipients outside the visible history' do
    let(:other_contact_recipient) do
      CampaignRecipient.create!(account: account, campaign: campaign, inbox: inbox,
                                contact: create(:contact, account: account), status: :sent, sent_at: sent_at)
    end
    let(:other_inbox_recipient) do
      other_channel = create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false)
      other_campaign = create(:campaign, account: account, inbox: other_channel.inbox)
      CampaignRecipient.create!(account: account, campaign: other_campaign, inbox: other_channel.inbox,
                                contact: conversation.contact, status: :sent, sent_at: sent_at)
    end
    let(:unsent_recipient) do
      CampaignRecipient.create!(account: account, campaign: create(:campaign, account: account, inbox: inbox), inbox: inbox,
                                contact: conversation.contact, status: :failed)
    end

    before do
      other_contact_recipient
      other_inbox_recipient
      unsent_recipient
    end

    it 'only returns sent records for the conversation contact and inbox' do
      recipient
      get url, headers: headers
      expect(response.parsed_body['payload'].pluck('id')).to eq([recipient.id])
    end

    %i[other_contact_recipient other_inbox_recipient unsent_recipient].each do |cursor|
      it "rejects #{cursor} as a cursor" do
        get url, params: { before: public_send(cursor).id }, headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'with multiple conversations' do
    let(:next_start) { sent_at + 1.hour }
    let!(:next_conversation) do
      create(:conversation, account: account, inbox: inbox, contact: conversation.contact, contact_inbox: conversation.contact_inbox,
                            created_at: next_start)
    end

    it 'includes the start boundary and excludes campaigns before it and at or after the next conversation' do
      times = [conversation.created_at - 1.second, conversation.created_at, sent_at, next_start, next_start + 1.second]
      records = times.map do |time|
        CampaignRecipient.create!(account: account, campaign: create(:campaign, account: account, inbox: inbox), inbox: inbox,
                                  contact: conversation.contact, status: :sent, sent_at: time)
      end

      get url, headers: headers
      expect(response.parsed_body['payload'].pluck('id')).to eq([records[2].id, records[1].id])
      expect(response.parsed_body['meta']['next_before']).to be_nil

      get "/api/v1/accounts/#{account.id}/conversations/#{next_conversation.display_id}/campaign_history", headers: headers
      expect(response.parsed_body['payload'].pluck('id')).to eq([records[4].id, records[3].id])
    end

    it 'rejects a cursor outside the conversation time window' do
      recipient.update!(sent_at: next_start)
      get url, params: { before: recipient.id }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'does not use other contacts or inboxes to end the conversation window' do
    create(:conversation, account: account, inbox: inbox, created_at: sent_at - 1.hour)
    create(:conversation, account: account, contact: conversation.contact, created_at: sent_at - 1.hour)
    recipient
    get url, headers: headers
    expect(response.parsed_body['payload'].pluck('id')).to eq([recipient.id])
  end

  context 'with pagination' do
    let!(:recipients) do
      Array.new(26) do |index|
        CampaignRecipient.create!(account: account, campaign: create(:campaign, account: account, inbox: inbox), inbox: inbox,
                                  contact: conversation.contact, status: :sent, sent_at: index.zero? ? sent_at + 1.hour : sent_at)
      end
    end

    it 'orders by send time and ID and traverses equal timestamps without duplicates or omissions' do
      expected_ids = [recipients.first.id] + recipients.drop(1).map(&:id).reverse
      get url, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['payload'].pluck('id')).to eq(expected_ids.first(25))
      expect(response.parsed_body['meta']['next_before']).to eq(expected_ids[24])

      get url, params: { before: response.parsed_body['meta']['next_before'] }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['payload'].pluck('id')).to eq(expected_ids.last(1))
      expect(response.parsed_body['meta']['next_before']).to be_nil
    end
  end

  ['', '0', '-1', '1.5', 'abc', ['1'], { id: '1' }].each do |cursor|
    it "rejects invalid cursor #{cursor.inspect}" do
      get url, params: { before: cursor }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'returns not found for a nonexistent cursor' do
    get url, params: { before: '999999999' }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'returns not found rather than a server error for an out-of-range cursor' do
    get url, params: { before: (2**63).to_s }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'omits history when the contact has multiple identities in the same inbox' do
    recipient
    other_identity = create(:contact_inbox, contact: conversation.contact, inbox: inbox)
    other_conversation = create(:conversation, account: account, inbox: inbox, contact: conversation.contact,
                                               contact_inbox: other_identity, created_at: sent_at - 1.hour)

    get url, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to be_empty

    get "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.display_id}/campaign_history", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to be_empty
  end
end
