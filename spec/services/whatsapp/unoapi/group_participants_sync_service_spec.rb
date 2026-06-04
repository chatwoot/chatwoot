require 'rails_helper'

describe Whatsapp::Unoapi::GroupParticipantsSyncService do
  subject(:service) { described_class.new(inbox: whatsapp_channel.inbox, conversation: conversation) }

  let(:whatsapp_channel) do
    create(
      :channel_whatsapp,
      phone_number: "+1555#{SecureRandom.random_number(1_000_000_000).to_s.rjust(9, '0')}",
      provider: 'unoapi',
      provider_config: {
        'url' => 'https://uno.example.com',
        'api_key' => 'test_key',
        'business_account_id' => '556600000000'
      },
      sync_templates: false,
      validate_provider_config: false
    )
  end

  let(:group_contact) { create(:contact, account: whatsapp_channel.account, name: 'Equipe Comercial', email: '120363040468224422@g.us') }
  let(:group_contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: group_contact, source_id: '120363040468224422@g.us') }
  let(:conversation) do
    create(
      :conversation,
      account: whatsapp_channel.account,
      inbox: whatsapp_channel.inbox,
      contact: group_contact,
      contact_inbox: group_contact_inbox,
      group: true,
      group_source_id: '120363040468224422@g.us',
      group_title: 'Equipe Comercial'
    )
  end

  let(:participants_url) { 'https://uno.example.com/v15.0/556600000000/groups/120363040468224422%40g.us/participants' }
  let(:details_url) { 'https://uno.example.com/v15.0/556600000000/groups/120363040468224422%40g.us' }
  let(:invite_link_url) { 'https://uno.example.com/v15.0/556600000000/groups/120363040468224422%40g.us/invite_link' }

  before do
    stub_request(:get, details_url).to_return(status: 404, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, invite_link_url).to_return(status: 403, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'hydrates group metadata and participants from Uno API' do
    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556600000000@s.whatsapp.net',
            wa_id: '556600000000',
            name: 'Sessao',
            is_admin: true,
            role: 'admin'
          },
          {
            jid: '556699999999@s.whatsapp.net',
            wa_id: '556699999999',
            user_id: '123456789012345@lid',
            username: '@maria.vendas',
            name: 'Maria',
            picture: 'https://cdn.example.com/profile/maria.jpg',
            lid: '123456789012345@lid',
            is_admin: true,
            role: 'admin'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    stub_request(:get, details_url).to_return(
      status: 200,
      body: {
        subject: 'Equipe Comercial VIP',
        description: 'Canal comercial',
        picture: 'https://cdn.example.com/groups/group.jpg',
        join_approval_mode: 'approval_required',
        creation_timestamp: '1710000000',
        suspended: false
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    stub_request(:get, invite_link_url).to_return(
      status: 200,
      body: { invite_link: 'https://chat.whatsapp.com/test' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.to have_enqueued_job(Avatar::AvatarFromUrlJob).with(group_contact, 'https://cdn.example.com/groups/group.jpg')

    conversation.reload
    expect(conversation.group_title).to eq('Equipe Comercial VIP')
    expect(conversation.group_description).to eq('Canal comercial')
    expect(conversation.group_invite_link).to eq('https://chat.whatsapp.com/test')
    expect(conversation.group_join_approval_mode).to eq('approval_required')
    expect(conversation.group_created_at_external).to eq(Time.zone.at(1_710_000_000))
    expect(conversation.group_suspended).to be(false)
    expect(conversation.additional_attributes['group_picture']).to eq('https://cdn.example.com/groups/group.jpg')
    expect(conversation.group_contacts_synced_at).to be_present
    expect(conversation.group_session_admin).to be(true)
    maria_group_contact = conversation.group_contacts.joins(:contact).find_by!(contacts: { name: 'Maria' })
    expect(maria_group_contact.metadata).to include(
      'role' => 'admin',
      'is_admin' => true,
      'lid' => '123456789012345@lid',
      'user_id' => '123456789012345@lid',
      'username' => '@maria.vendas'
    )
    expect(maria_group_contact.contact.name).to eq('Maria')
    expect(maria_group_contact.contact.bsuid).to eq('123456789012345@lid')
    expect(maria_group_contact.contact.whatsapp_username).to eq('@maria.vendas')
  end

  it 'stores false when the connected session is not an admin in the group' do
    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556600000000@s.whatsapp.net',
            wa_id: '556600000000',
            name: 'Sessao',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)
    expect(conversation.reload.group_session_admin).to be(false)
  end

  it 'preserves the existing group picture when Uno API returns an empty picture' do
    conversation.update!(additional_attributes: { 'group_picture' => 'https://cdn.example.com/groups/current.jpg' })
    stub_request(:get, details_url).to_return(
      status: 200,
      body: {
        subject: 'Equipe Comercial VIP',
        picture: ''
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        group: {
          picture: ''
        },
        participants: [
          {
            jid: '556600000000@s.whatsapp.net',
            wa_id: '556600000000',
            name: 'Sessao',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.not_to have_enqueued_job(Avatar::AvatarFromUrlJob).with(group_contact, '')
    expect(conversation.reload.additional_attributes['group_picture']).to eq('https://cdn.example.com/groups/current.jpg')
  end

  it 'preserves an existing participant profile picture when sync returns an empty profile_url' do
    participant_contact = create(:contact, account: whatsapp_channel.account, name: 'Maria')
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: participant_contact, source_id: '556699999999')
    create(
      :group_contact,
      conversation: conversation,
      contact: participant_contact,
      metadata: {
        jid: '556699999999@s.whatsapp.net',
        wa_id: '556699999999',
        picture: 'https://cdn.example.com/profile/current.jpg'
      }
    )

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699999999@s.whatsapp.net',
            wa_id: '556699999999',
            name: 'Maria',
            profile_url: ''
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.not_to have_enqueued_job(Avatar::AvatarFromUrlJob).with(participant_contact, '')

    group_contact = conversation.reload.group_contacts.find_by!(contact: participant_contact)
    expect(group_contact.metadata['picture']).to eq('https://cdn.example.com/profile/current.jpg')
  end

  it 'uses participant profile_url as the profile picture when present' do
    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699999999@s.whatsapp.net',
            wa_id: '556699999999',
            name: 'Maria',
            profile_url: 'https://cdn.example.com/profile/new.jpg'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.to have_enqueued_job(Avatar::AvatarFromUrlJob).with(
      instance_of(Contact),
      'https://cdn.example.com/profile/new.jpg'
    )

    group_contact = conversation.reload.group_contacts.joins(:contact).find_by!(contacts: { name: 'Maria' })
    expect(group_contact.metadata['picture']).to eq('https://cdn.example.com/profile/new.jpg')
  end

  it 'uses the merged participant contact to identify the connected session admin' do
    session_contact = create(:contact, account: whatsapp_channel.account, name: 'Sessao')
    session_contact.update_columns(phone_number: '+556600000000', bsuid: '94047083475061@lid') # rubocop:disable Rails/SkipsModelValidations
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: session_contact, source_id: '556600000000')
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: session_contact, source_id: '94047083475061@lid')
    create(:group_contact, conversation: conversation, contact: session_contact)

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '94047083475061@lid',
            user_id: '94047083475061@lid',
            name: 'Sessao',
            is_admin: true,
            role: 'admin'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)
    expect(conversation.reload.group_session_admin).to be(true)
  end

  it 'recalculates the connected session admin flag when the session member is demoted' do
    conversation.update!(group_session_admin: true)
    session_contact = create(:contact, account: whatsapp_channel.account, name: 'Sessao')
    session_contact.update_columns(phone_number: '+556600000000', bsuid: '94047083475061@lid') # rubocop:disable Rails/SkipsModelValidations
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: session_contact, source_id: '556600000000')
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: session_contact, source_id: '94047083475061@lid')
    create(:group_contact, conversation: conversation, contact: session_contact)

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '94047083475061@lid',
            user_id: '94047083475061@lid',
            name: 'Sessao',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)
    expect(conversation.reload.group_session_admin).to be(false)
  end

  it 'adds a system message when the connected session is no longer in the group' do
    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699554300',
            wa_id: '556699554300',
            user_id: '11343495192601@lid',
            name: 'Rodrigo',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.to change { conversation.messages.activity.count }.by(1)

    activity_message = conversation.messages.activity.last
    expect(activity_message.content).to eq(I18n.t('conversations.activity.whatsapp.group_session_removed'))
    expect(conversation.reload.additional_attributes['group_session_removed_at']).to be_present
  end

  it 'does not duplicate the system message while the connected session remains out of the group' do
    conversation.update!(additional_attributes: { 'group_session_removed_at' => Time.current.iso8601 })

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699554300',
            wa_id: '556699554300',
            user_id: '11343495192601@lid',
            name: 'Rodrigo',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect { service.perform }.not_to(change { conversation.messages.activity.count })
  end

  it 'clears the session removal marker when the connected session returns to the group' do
    conversation.update!(additional_attributes: { 'group_session_removed_at' => Time.current.iso8601 })

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556600000000@s.whatsapp.net',
            wa_id: '556600000000',
            name: 'Sessao',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)
    expect(conversation.reload.additional_attributes).not_to have_key('group_session_removed_at')
  end

  it 'clears invalid legacy participant email before updating the contact' do
    participant_contact = create(:contact, account: whatsapp_channel.account, name: 'Contato legado')
    participant_contact.update_columns(email: '47017208377581') # rubocop:disable Rails/SkipsModelValidations
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: participant_contact, source_id: '47017208377581@lid')

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '47017208377581@lid',
            user_id: '47017208377581@lid',
            name: 'Contato legado atualizado',
            username: '@legado'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)

    participant_contact.reload
    expect(participant_contact.email).to be_nil
    expect(participant_contact.bsuid).to eq('47017208377581@lid')
    expect(participant_contact.whatsapp_username).to eq('@legado')
  end

  it 'merges duplicated phone and lid participant contacts preferring the phone contact' do
    phone_contact = create(:contact, account: whatsapp_channel.account, name: 'ViperTec')
    phone_contact.update_columns(phone_number: '+5566996222471', email: '5566996222471') # rubocop:disable Rails/SkipsModelValidations
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: phone_contact, source_id: '5566996222471')
    phone_group_contact = create(:group_contact, conversation: conversation, contact: phone_contact)

    lid_contact = create(:contact, account: whatsapp_channel.account, name: 'Viper Tec', bsuid: '11343495192601@lid')
    lid_contact.avatar.attach(
      io: Rails.root.join('spec/assets/avatar.png').open,
      filename: 'avatar.png',
      content_type: 'image/png'
    )
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: lid_contact, source_id: '11343495192601@lid')
    create(:group_contact, conversation: conversation, contact: lid_contact, metadata: { jid: '11343495192601@lid' })

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '5566996222471@s.whatsapp.net',
            wa_id: '5566996222471',
            user_id: '11343495192601@lid',
            name: 'ViperTec'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)

    expect(phone_contact.reload.bsuid).to eq('11343495192601@lid')
    expect(phone_contact.avatar).to be_attached
    expect(phone_contact.email).to be_nil
    expect(Contact.exists?(lid_contact.id)).to be(false)
    expect(conversation.group_contacts.where(contact: phone_contact).count).to eq(1)
    expect(conversation.group_contacts.where(contact_id: lid_contact.id)).to be_blank
    expect(phone_group_contact.reload.metadata).to include('user_id' => '11343495192601@lid')
  end

  it 'syncs participants when legacy contacts already have a duplicated normalized phone number' do
    phone_contact = create(:contact, account: whatsapp_channel.account, name: 'Clara Souza')
    phone_contact.update_columns(phone_number: '+5566999139289') # rubocop:disable Rails/SkipsModelValidations
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: phone_contact, source_id: '5566999139289')

    duplicate_contact = create(:contact, account: whatsapp_channel.account, name: 'Clara duplicada')
    duplicate_contact.update_columns(phone_number: '+5566999139289') # rubocop:disable Rails/SkipsModelValidations

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699139289@s.whatsapp.net',
            wa_id: '556699139289',
            user_id: '224566693630048@lid',
            name: 'Clara Souza',
            username: '@clara'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)

    expect(phone_contact.reload.bsuid).to eq('224566693630048@lid')
    expect(phone_contact.whatsapp_username).to eq('@clara')
    expect(phone_contact.contact_inboxes.find_by!(inbox: whatsapp_channel.inbox, source_id: '556699139289')).to be_present
    expect(conversation.group_contacts.find_by!(contact: phone_contact).metadata).to include(
      'wa_id' => '556699139289',
      'user_id' => '224566693630048@lid'
    )
  end

  it 'removes group contacts that are no longer returned by Uno API' do
    stale_contact = create(:contact, account: whatsapp_channel.account, name: 'Membro removido')
    stale_contact.update_columns(phone_number: '+5566996222471') # rubocop:disable Rails/SkipsModelValidations
    stale_group_contact = create(:group_contact, conversation: conversation, contact: stale_contact)

    stub_request(:get, participants_url).to_return(
      status: 200,
      body: {
        participants: [
          {
            jid: '556699554300',
            wa_id: '556699554300',
            user_id: '11343495192601@lid',
            name: 'Rodrigo',
            is_admin: false,
            role: 'member'
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect(service.perform).to eq(:ok)

    expect(conversation.group_contacts.exists?(stale_group_contact.id)).to be(false)
    current_group_contact = conversation.group_contacts.joins(:contact).find_by!(contacts: { bsuid: '11343495192601@lid' })
    expect(current_group_contact.metadata).to include('wa_id' => '556699554300')
  end

  it 'returns cache_miss when Uno API does not have cached participants' do
    stub_request(:get, participants_url).to_return(status: 404, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(service.perform).to eq(:cache_miss)
    expect(conversation.reload.group_contacts_synced_at).to be_nil
  end
end
