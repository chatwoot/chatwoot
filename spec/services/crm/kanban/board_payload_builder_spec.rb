require 'rails_helper'

RSpec.describe Crm::Kanban::BoardPayloadBuilder do
  around do |example|
    with_modified_env CRM_KANBAN_ENABLED: 'true' do
      example.run
    end
  end

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create_crm_inbox(account: account, members: [admin]) }
  let(:pipeline_and_stage) { create_crm_pipeline(account: account, user: admin) }
  let(:pipeline) { pipeline_and_stage.first }
  let(:stage) { pipeline_and_stage.last }

  def create_conversation(campaign_source_ids: nil, labels: nil)
    contact = account.contacts.create!(name: "Lead #{SecureRandom.hex(3)}", phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    if campaign_source_ids.present?
      touches = campaign_source_ids.map do |sid|
        { 'source' => 'meta_ctwa', 'source_id' => sid, 'headline' => "Anúncio #{sid}", 'touched_at' => Time.current.utc.iso8601 }
      end
      conversation.update!(
        additional_attributes: conversation.additional_attributes.merge(
          'campaign_touches' => touches, 'campaign_source_ids' => campaign_source_ids
        )
      )
    end
    conversation.add_labels(labels) if labels.present?
    conversation
  end

  def create_card(conversation:, title: 'Card CTWA')
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, title: title,
      conversation_id: conversation.id, inbox_id: conversation.inbox_id, contact_id: conversation.contact_id
    )
  end

  def board_cards(params: {}, user: admin)
    context = Crm::Kanban::BoardContext.new(
      params: params,
      account: account,
      user: user,
      account_user: user.account_users.find_by(account: account)
    )
    payload = described_class.new(pipeline: pipeline, cards_scope: account.crm_cards, context: context).perform
    payload[:stages].flat_map { |stage_payload| stage_payload[:cards] }
  end

  it 'includes label titles and aggregated campaigns in every card payload' do
    account.labels.create!(title: 'vip')
    conversation = create_conversation(campaign_source_ids: %w[111], labels: %w[vip])
    create_card(conversation: conversation)

    card_payload = board_cards.first

    expect(card_payload[:labels]).to eq(%w[vip])
    expect(card_payload[:campaigns]).to eq(
      [{ source_id: '111', headline: 'Anúncio 111', source_url: nil,
         touched_at: conversation.additional_attributes['campaign_touches'].first['touched_at'], conversation_id: conversation.id }]
    )
  end

  it 'hides labels and campaigns when the primary conversation is invisible to the requester' do
    outsider = create(:user, account: account, role: :agent)
    account.labels.create!(title: 'vip')
    create_card(conversation: create_conversation(campaign_source_ids: %w[111], labels: %w[vip]))

    card_payload = board_cards(user: outsider).first

    expect(card_payload[:conversation_id]).to be_nil
    expect(card_payload[:labels]).to eq([])
    expect(card_payload[:campaigns]).to eq([])
  end

  it 'filters board cards by campaign_source_ids (csv, OR, any linked conversation)' do
    matched = create_card(conversation: create_conversation(campaign_source_ids: %w[111]))
    linked_match = create_card(conversation: create_conversation, title: 'Match via linkada')
    Crm::CardConversation.create!(account: account, card: linked_match, conversation: create_conversation(campaign_source_ids: %w[222]))
    create_card(conversation: create_conversation(campaign_source_ids: %w[333]), title: 'Fora do filtro')

    cards = board_cards(params: { campaign_source_ids: '111,222' })

    expect(cards.pluck(:id)).to contain_exactly(matched.id, linked_match.id)
  end

  it 'filters board cards by label_ids without duplicating a card with two matching labels' do
    vip = account.labels.create!(title: 'vip')
    quente = account.labels.create!(title: 'quente')
    matched = create_card(conversation: create_conversation(labels: %w[vip quente]))
    create_card(conversation: create_conversation, title: 'Sem etiqueta')

    cards = board_cards(params: { label_ids: "#{vip.id},#{quente.id}" })

    expect(cards.pluck(:id)).to eq([matched.id])
  end
end
