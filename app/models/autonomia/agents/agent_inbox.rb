module Autonomia
  module Agents
    # Vínculo agente nativo ↔ inbox (Fase C). UNIQUE em inbox_id garante 1 bot por inbox.
    # `agent_bot` é o AgentBot nativo-espelho (outgoing_url NULL) usado como sender canônico
    # da resposta outgoing — entra no fluxo de bot do core sem disparar webhook (Gabriela).
    class AgentInbox < ApplicationRecord
      self.table_name = 'autonomia_agent_inboxes'

      belongs_to :agent, class_name: 'Autonomia::Agents::Agent', foreign_key: :autonomia_agent_id
      belongs_to :inbox
      belongs_to :account
      # NON-optional: o AgentBot espelho é o sender canônico da resposta outgoing.
      # Sem ele a Message perde a identidade de AgentBot-sender (garantia anti-loop).
      belongs_to :agent_bot

      validates :inbox_id, uniqueness: true
      # Tenancy (defesa em profundidade): o runtime resolve o vínculo só por inbox_id
      # (Operate.eligible_agent_inbox), então um registro inconsistente cruzaria contas.
      validate :linked_records_must_belong_to_account

      # Limpeza do espelho ao destruir o vínculo — centraliza o conserto de "caixa deletada"
      # E "agente deletado" num só lugar. Dispara quando o vínculo cai por:
      #   • Inbox#destroy  → has_many :autonomia_agent_inboxes, dependent: :destroy
      #   • Agent#destroy  → has_many :agent_inboxes, dependent: :destroy
      # Sem isso, o AgentBot-espelho + AgentBotInbox vazariam (hoje só o InboxConnector#disconnect!
      # os remove). Espelho da nossa criação: outgoing_url NULL → NUNCA toca a Gabriela (webhook real).
      after_destroy :cleanup_mirror_bot

      private

      def linked_records_must_belong_to_account
        return if account_id.blank?

        %i[agent inbox agent_bot].each do |association_name|
          record = public_send(association_name)
          next if record.blank? || record.account_id == account_id

          errors.add(association_name, 'must belong to the same account')
        end
      end

      def cleanup_mirror_bot
        AgentBotInbox.where(inbox_id: inbox_id, agent_bot_id: agent_bot_id).destroy_all
        # Guarda dura: só remove o AgentBot se for o espelho (outgoing_url NULL). Um bot webhook
        # (Gabriela) jamais é apagado por este caminho, mesmo que algum dado fique inconsistente.
        AgentBot.where(id: agent_bot_id, outgoing_url: nil).find_each(&:destroy)
      end
    end
  end
end
