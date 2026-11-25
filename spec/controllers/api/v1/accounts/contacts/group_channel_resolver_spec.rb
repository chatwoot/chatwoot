require 'rails_helper'

# A group contact is account-scoped, so one WhatsApp group can belong to two inboxes of
# the same account. Every group action used to resolve its channel by taking whichever
# contact inbox came first, while the dashboard decided what the agent may do from the
# inbox they had open: the panel granted the action using one inbox's capabilities and
# admin status, and the server performed it as another. Leaving is the worst of them,
# because it removes the wrong number from the group.
#
# Asserted on `group_admin#leave`, which is the destructive one, and on the ambiguity
# itself, which every group endpoint answers the same way through the shared concern.
RSpec.describe 'group actions and the inbox they run as', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:looking_at) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
  end
  let(:other) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
  end
  let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: '120363041234567890@g.us') }

  before do
    # `other` first, so taking whichever comes first is the wrong answer.
    create(:contact_inbox, contact: group_contact, inbox: other.inbox, source_id: '120363041234567890')
    create(:contact_inbox, contact: group_contact, inbox: looking_at.inbox, source_id: '120363041234567890')
  end

  it 'leaves the group as the inbox the caller named' do
    left_as = []
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new) do |whatsapp_channel:|
      instance_double(Whatsapp::Providers::WhatsappBaileysService).tap do |service|
        allow(service).to receive(:group_leave) { left_as << whatsapp_channel }
      end
    end

    post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
         params: { inbox_id: looking_at.inbox.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(left_as).to eq([looking_at])
  end

  it 'refuses an inbox this group is not in' do
    stranger = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                         account: account)

    post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
         params: { inbox_id: stranger.inbox.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it 'refuses to guess when the caller names none' do
    post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
         headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:bad_request)
  end

  # `ContactPolicy` lets every agent of the account read and update a contact, which was
  # harmless while the inbox was ours to pick. Naming one is a request, so without this an
  # agent on one inbox could leave the group, promote or remove members as another.
  it 'refuses an inbox the agent is not on' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, user: agent, inbox: looking_at.inbox)

    post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
         params: { inbox_id: other.inbox.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  # An agent on none of the group's inboxes has no candidate at all, and `size <= 1` read
  # that as "exactly one", handing a nil channel to the action. The first dereference
  # raised, so a request that is simply not this agent's answered 500.
  #
  # The answer has to be the one an inbox the group is not in already gets. Answering
  # differently would tell an agent whether that number is in the group, which is the
  # disclosure the named-inbox path is careful to avoid.
  context 'when the agent is on none of the inboxes this group is in' do
    let(:outsider) do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, user: agent,
                            inbox: create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false,
                                                             sync_templates: false, account: account).inbox)
      agent
    end

    it 'refuses instead of failing, when the caller names no inbox' do
      post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
           headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    # The same request the previous example makes, from an agent who is on one of them.
    # Both are refused, and the refusals are indistinguishable.
    it 'answers exactly as it does for an inbox the group is not in' do
      stranger = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                           account: account)
      insider = create(:user, account: account, role: :agent)
      create(:inbox_member, user: insider, inbox: looking_at.inbox)

      post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
           headers: outsider.create_new_auth_token, as: :json
      absent_inbox = [response.status, response.parsed_body]

      post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
           params: { inbox_id: stranger.inbox.id }, headers: insider.create_new_auth_token, as: :json

      expect(absent_inbox).to eq([response.status, response.parsed_body])
    end
  end

  # The read that tolerates a missing channel must still refuse an inbox that was named and
  # is wrong. Without the bang it would answer 200 with the list and no admin flag, turning a
  # wrong request into a slightly wrong answer.
  it 'refuses a named inbox the group is not in even on the tolerant read' do
    stranger = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                         account: account)

    get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
        params: { inbox_id: stranger.inbox.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  # A fence, not a checklist. There used to be a nil-tolerant reader beside `channel`, for the
  # roster read, and what it produced was one endpoint answering the same question two ways
  # depending on whether an optional parameter was typed. Its absence is what keeps the next
  # group endpoint from reaching for one because it happens to be nearby.
  it 'has no nil-tolerant way to resolve the channel' do
    roots = %w[app enterprise lib].select { |dir| Rails.root.join(dir).directory? }
    sources = Dir.glob(Rails.root.join("{#{roots.join(',')}}/**/*.rb"))
    readers = sources.select { |path| File.read(path).include?('channel_if_any') }

    expect(sources).not_to be_empty
    expect(readers.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s }).to be_empty
  end

  # The half of #535 this closes: same caller, same contact, same authorisation question, and
  # until now two answers depending on whether `inbox_id` was typed.
  describe 'the roster read' do
    let(:outsider) do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, user: agent,
                            inbox: create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false,
                                                             sync_templates: false, account: account).inbox)
      agent
    end

    it 'answers an agent on none of this group\'s inboxes the same way, named or not' do
      get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
          headers: outsider.create_new_auth_token, as: :json
      unnamed = [response.status, response.parsed_body]

      get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
          params: { inbox_id: looking_at.inbox.id }, headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
      expect(unnamed).to eq([response.status, response.parsed_body])
    end

    # And it still answers the agent who has a claim, without being told which inbox to use, which
    # is the case the parameter was made optional for.
    it 'still answers an agent who is on one of them, without being told which' do
      insider = create(:user, account: account, role: :agent)
      create(:inbox_member, user: insider, inbox: looking_at.inbox)

      get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
          headers: insider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  # A metadata write resolved the channel only when it had a field to write, so a request with no
  # subject, description or avatar never reached the refusal: it answered 200 to a caller the very
  # same request would have been refused for the moment it carried one field.
  describe 'a metadata write with nothing in it' do
    it 'refuses an inbox the agent is not on, as it does with a field' do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, user: agent, inbox: looking_at.inbox)

      patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
            params: { inbox_id: other.inbox.id }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses an agent on none of this group\'s inboxes' do
      outsider = create(:user, account: account, role: :agent)
      create(:inbox_member, user: outsider,
                            inbox: create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false,
                                                             sync_templates: false, account: account).inbox)

      patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
            headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    # Before the body is read at all, not merely before the fields are written. A description sent
    # empty is refused with a 422 that explains the rule, and answering that to a caller with no
    # claim to any of this group's inboxes tells them about a group they were not to be told about,
    # in a request that should have ended one line earlier.
    it 'refuses before it explains why an empty description is not allowed' do
      outsider = create(:user, account: account, role: :agent)
      create(:inbox_member, user: outsider,
                            inbox: create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false,
                                                             sync_templates: false, account: account).inbox)

      patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
            params: { description: '' }, headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'is still a no-op success for a caller who could have written' do
      patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
            params: { inbox_id: looking_at.inbox.id }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  # The endpoints predate the parameter and are documented without it, so a group that is
  # in one inbox still answers on its own.
  it 'needs no inbox when the group is in only one' do
    group_contact.contact_inboxes.where(inbox: other.inbox).destroy_all
    service = instance_double(Whatsapp::Providers::WhatsappBaileysService, group_leave: true)
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(service)

    post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_admin/leave",
         headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
  end
end
