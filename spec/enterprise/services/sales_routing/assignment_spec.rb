require 'rails_helper'

RSpec.describe SalesRouting::Assignment do
  let(:account) { create(:account) }
  let(:role) { create(:custom_role, account: account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true, timezone: 'America/Sao_Paulo', working_hours_enabled: true) }
  let(:seller) { create(:user, account: account, role: :agent) }
  let(:other_seller) { create(:user, account: account, role: :agent) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:psd) { create(:team, account: account) }
  let(:lap) { create(:team, account: account) }
  let(:tat) { create(:team, account: account) }
  let(:policy) do
    create(:assignment_policy, account: account, assignment_order: :balanced, eligible_custom_role: role,
                               business_hours_only: true, conversation_priority: :latest_customer_message,
                               fair_distribution_limit: 10, fair_distribution_window: 3600)
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil) }
  let(:service) { AutoAssignment::AssignmentService.new(inbox: inbox) }

  before do
    travel_to Time.zone.parse('2026-10-12 15:00:00 UTC')
    account.enable_features!('assignment_v2', 'advanced_assignment')
    create(:inbox_assignment_policy, inbox: inbox, assignment_policy: policy)
    [seller, other_seller, manager].each { |user| create(:inbox_member, inbox: inbox, user: user) }
    [seller, other_seller].each { |user| user.account_users.find_by!(account: account).update!(custom_role: role) }
    create(:team_member, team: psd, user: seller)
    create(:team_member, team: psd, user: manager)
    create(:team_member, team: lap, user: other_seller)
    account.update!(internal_attributes: {
                      store_routing: { inbox_ids: [inbox.id], stores: {
                        psd: { team_id: psd.id, label: 'loja-psd' }, lap: { team_id: lap.id, label: 'loja-lap' },
                        tat: { team_id: tat.id, label: 'loja-tat' }
                      } }, assignment_ledger: { inbox_ids: [inbox.id] }
                    })
    online = { seller.id.to_s => 'online', other_seller.id.to_s => 'online', manager.id.to_s => 'online' }
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(online)
  end

  it 'routes case-insensitive store codes and records an automatic event in the assignment transaction' do
    message = create(:message, account: account, conversation: conversation, content: 'Produto [pSd] · ref: psd-jantar', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload).to have_attributes(assignee_id: seller.id, team_id: psd.id)
    expect(conversation.label_list).to include('loja-psd', 'origem-site')
    expect(conversation.custom_attributes['campanha']).to eq('psd-jantar')
    expect(message.reload.content).to eq('Produto [pSd] · ref: psd-jantar')
    expect(conversation.conversation_assignment_events.last).to have_attributes(agent_id: seller.id, source: 'automatic', event_kind: 'initial')
    service.perform_bulk_assignment
    expect(conversation.conversation_assignment_events.count).to eq(1)
  end

  it 'waits for the first message and for the five-second enrichment window' do
    conversation
    expect(service.perform_bulk_assignment).to eq(0)
    create(:message, account: account, conversation: conversation, content: '[LAP]')
    expect(service.perform_bulk_assignment).to eq(0)
    travel 5.seconds
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(other_seller.id)
  end

  it 'falls back to another online store while retaining the requested store label' do
    create(:message, account: account, conversation: conversation, content: '[TAT]', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.label_list).to include('loja-tat')
    expect(conversation.team.members).to include(conversation.assignee)
    expect(conversation.conversation_assignment_events.last.routing['assignment_rule']).to eq('fallback-geral')
  end

  it 'keeps a saturated online store waiting instead of bypassing its hourly limit' do
    policy.update!(fair_distribution_limit: 1)
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    AutoAssignment::RateLimiter.new(inbox: inbox, agent: seller).track_assignment(conversation)
    expect(service.perform_bulk_assignment).to eq(0)
    expect(conversation.reload.assignee_id).to be_nil
    travel 1.hour + 1.second
    expect(service.perform_bulk_assignment).to eq(1)
  end

  it 'preserves manually assigned conversations and freezes the original store on later messages' do
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    conversation.update!(assignee: manager)
    SalesRouting::ClassifyJob.perform_now(conversation.id)
    create(:message, account: account, conversation: conversation, content: '[LAP]')
    SalesRouting::ClassifyJob.perform_now(conversation.id)
    expect(conversation.reload.assignee).to eq(manager)
    expect(conversation.label_list).to include('loja-psd')
    expect(conversation.label_list).not_to include('loja-lap')
  end

  it 'uses the same store and eligible seller for a returning phone within sixty days' do
    previous = create(:conversation, account: account, inbox: inbox, contact: conversation.contact, team: lap, assignee: other_seller,
                                     status: :resolved, last_activity_at: 30.days.ago)
    create(:message, account: account, conversation: conversation, content: 'Voltei', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(previous.assignee_id)
    expect(conversation.label_list).to include('loja-lap')
    expect(conversation.conversation_assignment_events.last.routing['rule']).to eq('cliente-voltou')
  end

  it 'labels outside business hours without assigning and drains the older overnight lead first' do
    travel_to Time.zone.parse('2026-10-12 10:00:00 UTC')
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    SalesRouting::ClassifyJob.perform_now(conversation.id)
    expect(service.perform_bulk_assignment).to eq(0)
    expect(conversation.reload.label_list).to include('loja-psd')
    travel_to Time.zone.parse('2026-10-12 12:01:00 UTC')
    newer = create(:conversation, account: account, inbox: inbox, assignee: nil)
    create(:message, account: account, conversation: newer, content: '[PSD]', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment(limit: 1)).to eq(1)
    expect(conversation.reload.assignee_id).to eq(seller.id)
    expect(newer.reload.assignee_id).to be_nil
  end

  it 'distributes an unknown-store batch one per available seller before repeating' do
    2.times do
      lead = create(:conversation, account: account, inbox: inbox, assignee: nil)
      create(:message, account: account, conversation: lead, content: 'Olá', created_at: 10.seconds.ago)
    end
    expect(service.perform_bulk_assignment).to eq(2)
    expect(inbox.conversations.open.pluck(:assignee_id)).to contain_exactly(seller.id, other_seller.id)
  end

  it 'rolls the assignment back if its durable ledger cannot be written' do
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    allow(ConversationAssignmentEvent).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap { |event| allow(event).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }
    end
    expect { service.perform_bulk_assignment }.to raise_error(ActiveRecord::RecordInvalid)
    expect(conversation.reload.assignee_id).to be_nil
  end

  it 'records a transfer separately from the first assignment' do
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    service.perform_bulk_assignment
    conversation.reload.update!(team: lap, assignee: other_seller)
    expect(conversation.conversation_assignment_events.order(:id).pluck(:event_kind)).to eq(%w[initial reassignment])
  end

  it 'uses structured campaign metadata when the customer removed the code' do
    create(:message, account: account, conversation: conversation, content: 'Olá', created_at: 10.seconds.ago)
    ad = MetaAd.create!(ad_id: 'routing-ad', campaign_name: 'MENSAGEM - LAPA')
    ConversationAdReferral.create!(account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                                   ad_id: ad.ad_id, source_type: 'ad', raw: {}, referred_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(other_seller.id)
    expect(conversation.label_list).to include('loja-lap', 'origem-meta')
  end

  it 'does not route from internal notes or partial words in campaign names' do
    create(:message, account: account, conversation: conversation, content: 'Olá', created_at: 10.seconds.ago)
    create(:message, account: account, conversation: conversation, content: '[PSD]', message_type: :outgoing, private: true)
    ad = MetaAd.create!(ad_id: 'routing-ad', campaign_name: 'ESTATUA - COLAPSO')
    ConversationAdReferral.create!(account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                                   ad_id: ad.ad_id, source_type: 'ad', raw: {}, referred_at: 10.seconds.ago)
    SalesRouting::ClassifyJob.perform_now(conversation.id)
    expect(conversation.reload.label_list).to include('loja-indefinida')
  end

  it 'leaves other inboxes on their native assignment policy' do
    other_inbox = create(:inbox, account: account, enable_auto_assignment: true)
    create(:inbox_assignment_policy, inbox: other_inbox, assignment_policy: policy)
    create(:inbox_member, inbox: other_inbox, user: seller)
    other = create(:conversation, account: account, inbox: other_inbox, assignee: nil)
    expect(AutoAssignment::AssignmentService.new(inbox: other_inbox).perform_bulk_assignment).to eq(1)
    expect(other.reload.assignee_id).to eq(seller.id)
    expect(other.additional_attributes).not_to have_key('store_routing')
  end

  it 'respects a disabled team instead of automatically moving its conversations' do
    psd.update!(allow_auto_assign: false)
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(0)
    expect(conversation.reload.assignee_id).to be_nil
  end

  it 'uses changed team membership on the next assignment run' do
    psd.team_members.where(user_id: seller.id).destroy_all
    lap.team_members.where(user_id: other_seller.id).destroy_all
    create(:team_member, team: psd, user: other_seller)
    create(:message, account: account, conversation: conversation, content: '[PSD]', created_at: 10.seconds.ago)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(other_seller.id)
  end
end
