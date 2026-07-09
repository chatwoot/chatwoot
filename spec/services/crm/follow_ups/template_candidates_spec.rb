require 'rails_helper'

RSpec.describe Crm::FollowUps::TemplateCandidates do
  def whatsapp_template(name:, category:, status: 'APPROVED', body: 'Olá {{1}}')
    {
      'name' => name,
      'status' => status,
      'category' => category,
      'language' => 'pt_BR',
      'components' => [{ 'type' => 'BODY', 'text' => body }]
    }
  end

  def build_native_conversation(account:, templates:)
    channel = create(:channel_whatsapp, account: account, sync_templates: false,
                                        validate_provider_config: false, message_templates: templates)
    inbox = channel.inbox
    contact = create(:contact, account: account, phone_number: '+5511987654321')
    create(:conversation, account: account, inbox: inbox, contact: contact)
  end

  it 'includes an approved MARKETING native template with category "marketing"' do
    account = create(:account)
    conversation = build_native_conversation(
      account: account,
      templates: [whatsapp_template(name: 'promo_retorno', category: 'MARKETING', body: 'Volte {{1}}')]
    )

    candidates = described_class.new(conversation: conversation).perform

    expect(candidates.size).to eq(1)
    expect(candidates.first).to include(kind: 'native', name: 'promo_retorno', category: 'marketing')
  end

  it 'includes an approved UTILITY native template with category "utility"' do
    account = create(:account)
    conversation = build_native_conversation(
      account: account,
      templates: [whatsapp_template(name: 'pedido_atualizado', category: 'UTILITY', body: 'Seu pedido {{1}}')]
    )

    candidates = described_class.new(conversation: conversation).perform

    expect(candidates.size).to eq(1)
    expect(candidates.first).to include(kind: 'native', name: 'pedido_atualizado', category: 'utility')
  end

  it 'excludes AUTHENTICATION templates while keeping marketing and utility' do
    account = create(:account)
    conversation = build_native_conversation(
      account: account,
      templates: [
        whatsapp_template(name: 'promo_retorno', category: 'MARKETING'),
        whatsapp_template(name: 'pedido_atualizado', category: 'UTILITY'),
        whatsapp_template(name: 'login_code', category: 'AUTHENTICATION')
      ]
    )

    candidates = described_class.new(conversation: conversation).perform

    names = candidates.map { |candidate| candidate[:name] }
    categories = candidates.map { |candidate| candidate[:category] }
    expect(names).to contain_exactly('promo_retorno', 'pedido_atualizado')
    expect(categories).to contain_exactly('marketing', 'utility')
    expect(names).not_to include('login_code')
  end
end
