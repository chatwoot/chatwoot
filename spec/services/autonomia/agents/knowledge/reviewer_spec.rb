require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Reviewer do
  describe '.recompute_overall!' do
    let(:account) { create(:account) }
    let(:agent) do
      Autonomia::Agents::Agent.create!(account: account, name: 'Agente Teste', agent_type: 'support')
    end
    # Sem credencial de IA o topic_map degrada para a derivação determinística (resumos), o que
    # torna o teste estável e sem chamadas externas.
    let(:resolver) { instance_double(Crm::Ai::CredentialResolver, resolve: nil) }

    before do
      allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(resolver)
    end

    def create_source(status:, review_status:, summary: nil, score: nil)
      Autonomia::Agents::Source.create!(
        account: account, agent: agent, source_type: 'txt', status: status,
        review_status: review_status, review_summary: summary,
        quality_score: score, metadata: { 'chunk_count' => 1 }
      )
    end

    it 'keeps an accepted source that failed transiently in the topic_map and knowledge_summary (G6)' do
      # Arrange — fonte boa que falhou num re-sync transitório: mark_failed! restaurou o parecer
      # 'accepted' (entries antigos seguem servíveis via Retriever), mas o status ficou 'failed'.
      create_source(status: :ready, review_status: 'accepted',
                    summary: 'Horários e políticas de atendimento.', score: 90)
      create_source(status: :failed, review_status: 'accepted',
                    summary: 'Tabela de preços dos planos.', score: 90)

      # Act
      described_class.recompute_overall!(agent)

      # Assert — os temas da fonte failed+accepted NÃO somem do agregado.
      agent.reload
      expect(agent.topic_map).to contain_exactly(
        'Horários e políticas de atendimento.', 'Tabela de preços dos planos.'
      )
      expect(agent.knowledge_summary).to be_present
      expect(agent.knowledge_confidence.to_f).to eq(0.9)
    end

    it 'excludes failed sources that were never accepted' do
      # Arrange — primeira ingestão falhou: previous_review_attributes restaura como needs_review
      # (nunca-revisada não é promovida) e a fonte não pode alimentar o agregado.
      create_source(status: :ready, review_status: 'accepted',
                    summary: 'Horários e políticas de atendimento.', score: 90)
      create_source(status: :failed, review_status: 'needs_review',
                    summary: 'Resumo órfão que não deve entrar.')

      # Act
      described_class.recompute_overall!(agent)

      # Assert
      agent.reload
      expect(agent.topic_map).to contain_exactly('Horários e políticas de atendimento.')
    end
  end
end
