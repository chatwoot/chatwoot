require 'rails_helper'

# Reaper de rascunhos órfãos do Construtor. Cada caso cobre um failure mode do job destrutivo:
# varrer o órfão de verdade, e NUNCA tocar agente ativo, rascunho com atividade recente (no agente
# ou na thread), agente manual, ou reabrir a janela por engano.
RSpec.describe Autonomia::Agents::ReapStaleDraftsJob, type: :job do
  let(:account) { create(:account) }

  def create_agent(status: :draft, enabled: false, mode: :guided, updated_ago: 3.days)
    agent = Autonomia::Agents::Agent.create!(
      account: account, name: 'Novo agente', agent_type: 'custom',
      mode: mode, status: status, enabled: enabled, actuation: :external
    )
    # update_column pula o touch de updated_at para simular inatividade.
    agent.update_column(:updated_at, updated_ago.ago) # rubocop:disable Rails/SkipsModelValidations
    agent
  end

  it 'reaps a guided draft with no activity past the window' do
    orphan = create_agent

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(orphan.id)).to be(false)
  end

  it 'cascades the destroy to the draft sources' do
    orphan = create_agent
    source = Autonomia::Agents::Source.create!(
      account: account, agent: orphan, source_type: 'txt', reference: 'faq.txt'
    )
    # fonte também velha, senão a proteção de atividade recente pouparia o agente.
    source.update_column(:updated_at, 3.days.ago) # rubocop:disable Rails/SkipsModelValidations

    described_class.new.perform

    expect(Autonomia::Agents::Source.exists?(source.id)).to be(false)
  end

  it 'spares a draft whose build thread was active within the window' do
    agent = create_agent
    # thread recém-tocada mesmo com o agente velho — sinal de construção em andamento.
    Autonomia::Agents::BuildThread.create!(account: account, agent: agent)

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(agent.id)).to be(true)
  end

  it 'spares a recently updated draft' do
    fresh = create_agent(updated_ago: 1.hour)

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(fresh.id)).to be(true)
  end

  it 'spares a stale draft that has a recently uploaded source (KB-first user)' do
    agent = create_agent
    # fonte recém-criada (upload horas depois, sem conversar) mantém o agente vivo.
    Autonomia::Agents::Source.create!(
      account: account, agent: agent, source_type: 'txt', reference: 'faq.txt'
    )

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(agent.id)).to be(true)
  end

  it 'still reaps the orphan when an unrelated recent thread has a nil agent (NULL subquery guard)' do
    orphan = create_agent
    # thread recém-criada SEM agente (nasce antes do link) — um NULL na subquery de NOT IN
    # zeraria toda a varredura se não fosse filtrado.
    Autonomia::Agents::BuildThread.create!(account: account)

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(orphan.id)).to be(false)
  end

  it 'never reaps an active agent even when stale' do
    active = create_agent(status: :active, enabled: true)

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(active.id)).to be(true)
  end

  it 'never reaps a manual agent' do
    manual = create_agent(mode: :manual)

    described_class.new.perform

    expect(Autonomia::Agents::Agent.exists?(manual.id)).to be(true)
  end
end
