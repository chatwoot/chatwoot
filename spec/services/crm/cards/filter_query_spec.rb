require 'rails_helper'

RSpec.describe Crm::Cards::FilterQuery do
  around do |example|
    previous_value = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    example.run
  ensure
    if previous_value.nil?
      ENV.delete('CRM_KANBAN_ENABLED')
    else
      ENV['CRM_KANBAN_ENABLED'] = previous_value
    end
  end

  let(:account_and_user) { create_account_and_user }
  let(:account) { account_and_user.first }
  let(:user) { account_and_user.last }

  # status `open` here is the in-funnel deal status, NOT the conversation status.
  def seed_cards
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    {
      open: account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Em andamento', status: :open),
      won: account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Ganho', status: :won),
      lost: account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Perdido', status: :lost),
      archived: account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Arquivado', status: :archived),
    }
  end

  def perform(result)
    described_class.new(scope: account.crm_cards, params: { result: result }).perform
  end

  it 'returns only in-funnel (open) cards when result=open' do
    cards = seed_cards
    expect(perform('open')).to contain_exactly(cards[:open])
  end

  it 'returns only won cards when result=won' do
    cards = seed_cards
    expect(perform('won')).to contain_exactly(cards[:won])
  end

  it 'returns only lost cards when result=lost' do
    cards = seed_cards
    expect(perform('lost')).to contain_exactly(cards[:lost])
  end

  it 'returns only archived cards when result=archived' do
    cards = seed_cards
    expect(perform('archived')).to contain_exactly(cards[:archived])
  end

  it 'does not filter by status when result is blank' do
    cards = seed_cards
    expect(perform('')).to match_array(cards.values)
  end

  it 'ignores an unknown result value' do
    cards = seed_cards
    expect(perform('bogus')).to match_array(cards.values)
  end

  describe 'campaign and label filters' do
    def perform_with(params)
      described_class.new(scope: account.crm_cards, params: params).perform
    end

    def create_conversation(inbox:, campaign_source_ids: nil, labels: nil)
      contact = account.contacts.create!(name: "Lead #{SecureRandom.hex(3)}", phone_number: "+55119#{rand(10_000_000..99_999_999)}")
      conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
      if campaign_source_ids.present?
        touches = campaign_source_ids.map { |sid| { 'source' => 'meta_ctwa', 'source_id' => sid, 'touched_at' => Time.current.utc.iso8601 } }
        conversation.update!(
          additional_attributes: conversation.additional_attributes.merge(
            'campaign_touches' => touches, 'campaign_source_ids' => campaign_source_ids
          )
        )
      end
      conversation.add_labels(labels) if labels.present?
      conversation
    end

    def create_card(conversation: nil, title: 'Card CTWA')
      pipeline, stage = create_crm_pipeline(account: account, user: user, name: "Funil #{SecureRandom.hex(3)}")
      account.crm_cards.create!(
        pipeline: pipeline, stage: stage, title: title,
        conversation_id: conversation&.id, inbox_id: conversation&.inbox_id, contact_id: conversation&.contact_id
      )
    end

    it 'matches a card whose primary conversation touched any of the csv campaign ids' do
      inbox = create_crm_inbox(account: account, members: [user])
      matched = create_card(conversation: create_conversation(inbox: inbox, campaign_source_ids: %w[123]))
      create_card(conversation: create_conversation(inbox: inbox, campaign_source_ids: %w[456]), title: 'Outro anúncio')

      expect(perform_with(campaign_source_ids: '123,999')).to contain_exactly(matched)
    end

    it 'matches through a linked (non-primary) conversation and excludes standalone cards' do
      inbox = create_crm_inbox(account: account, members: [user])
      card = create_card(conversation: create_conversation(inbox: inbox))
      linked = create_conversation(inbox: inbox, campaign_source_ids: %w[789])
      Crm::CardConversation.create!(account: account, card: card, conversation: linked)
      create_card(title: 'Standalone sem conversa')

      expect(perform_with(campaign_source_ids: '789')).to contain_exactly(card)
    end

    it 'does not match a campaign id by substring (quoted-token semantics)' do
      inbox = create_crm_inbox(account: account, members: [user])
      create_card(conversation: create_conversation(inbox: inbox, campaign_source_ids: %w[4567]))

      expect(perform_with(campaign_source_ids: '456')).to be_empty
    end

    it 'filters by label ids of the primary conversation without duplicating the card' do
      inbox = create_crm_inbox(account: account, members: [user])
      vip = account.labels.create!(title: 'vip')
      premium = account.labels.create!(title: 'premium')
      matched = create_card(conversation: create_conversation(inbox: inbox, labels: %w[vip premium]))
      create_card(conversation: create_conversation(inbox: inbox), title: 'Sem etiqueta')

      result = perform_with(label_ids: "#{vip.id},#{premium.id}")

      expect(result.to_a).to eq([matched])
    end

    it 'ignores labels that only exist on a linked non-primary conversation' do
      inbox = create_crm_inbox(account: account, members: [user])
      vip = account.labels.create!(title: 'vip')
      card = create_card(conversation: create_conversation(inbox: inbox))
      linked = create_conversation(inbox: inbox, labels: %w[vip])
      Crm::CardConversation.create!(account: account, card: card, conversation: linked)

      expect(perform_with(label_ids: vip.id.to_s)).to be_empty
    end
  end
end
