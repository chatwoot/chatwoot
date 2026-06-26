# frozen_string_literal: true

require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: regressão do /live 500.
# A classe usa a forma compacta `class Synapseos::AgentMetricsQuery`, então o
# lexical scope é só [Synapseos::AgentMetricsQuery] — NÃO inclui Synapseos.
# Referenciar `AgentResolver` sem prefixo não resolvia `Synapseos::AgentResolver`
# -> NameError -> 500 em live/show/usage (index funcionava porque o controller
# já qualificava com ::Synapseos::AgentResolver). Estes specs falhariam com
# NameError antes do fix.
RSpec.describe Synapseos::AgentMetricsQuery do
  let(:account) { create(:account) }

  describe '.live' do
    it 'resolve ::Synapseos::AgentResolver e devolve o payload (sem NameError/500)' do
      expect { described_class.live(account: account) }.not_to raise_error

      payload = described_class.live(account: account)
      expect(payload).to include(:agents, :hot_conversations)
      expect(payload[:agents].map { |a| a[:slug] }).to match_array(Synapseos::AgentResolver::SLUGS)
    end
  end

  describe '.for_agent' do
    it 'resolve o resolver e devolve KPIs por agente (sem NameError)' do
      expect do
        described_class.for_agent(account: account, slug: 'natalia', since: 30.days.ago)
      end.not_to raise_error
    end
  end

  describe '.usage_for_agent' do
    it 'resolve o resolver e devolve consumo mensal (sem NameError)' do
      expect do
        described_class.usage_for_agent(account: account, slug: 'natalia')
      end.not_to raise_error
    end
  end
end
