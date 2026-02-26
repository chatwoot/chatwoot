# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateOrderTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:product) { create(:product, account: account, price: 25.00, stock: 10) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes order creation' do
      expect(described_class.description).to include('order')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }
    let(:items_json) { [{ product_id: product.id, quantity: 2 }].to_json }

    context 'without required context' do
      before { Aloo::Current.conversation = nil }

      it 'returns error response' do
        result = tool.execute(items: items_json)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end

    context 'in playground mode' do
      before { Aloo::Current.playground_mode = true }

      after { Aloo::Current.playground_mode = nil }

      it 'returns a simulated response' do
        result = tool.execute(items: items_json)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('Playground')
      end
    end

    context 'when catalog is not enabled' do
      it 'returns error about catalog not enabled' do
        result = tool.execute(items: items_json)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Catalog is not enabled')
      end
    end

    context 'with invalid JSON items' do
      it 'returns error about invalid format' do
        result = tool.execute(items: 'not-json')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid items format')
      end
    end
  end
end
