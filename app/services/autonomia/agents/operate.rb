module Autonomia
  module Agents
    # Namespace-módulo da camada "Operar". Coexiste com o diretório homônimo
    # app/services/autonomia/agents/operate/*.rb (Zeitwerk: módulo + diretório de mesmo nome).
    # Mantém o guard-rail de teste (allowlist), fonte única consumida pelos gates do operate.
    module Operate
      # Predicado CANÔNICO de elegibilidade do operate (modelo instrução-dirigido). Re-deriva o
      # AgentInbox a partir do inbox ATUAL da conversa (a conversa pode ter mudado de caixa) e valida o
      # CONTRATO INTEIRO: feature habilitada na conta + conversa SEM responsável + agente ligado àquela
      # caixa + habilitado + ativo + não-interno + não-sistema + allowlist de teste. STATUS é irrelevante.
      # Usado pelo ReplyJob (decidir agir) E no momento de postar (Responder/ChunkedDelivery), com estado
      # FRESCO, para nunca postar se algo mudou durante a chamada de IA (humano assumiu, agente desligado,
      # conversa movida de caixa). Devolve o AgentInbox ou nil.
      def self.eligible_agent_inbox(conversation)
        return if conversation.blank? || conversation.assignee_id.present?
        return unless ::Autonomia::Agents::Config.enabled?(conversation.account)

        # TENANCY FAIL-CLOSED na LEITURA (par do validate do AgentInbox, que só protege a ESCRITA):
        # a query é escopada pela conta da conversa e o agente resolvido precisa ser da MESMA conta.
        # Um vínculo legado/corrompido (criado antes da validação ou por write que burla o Rails)
        # jamais pode fazer a conversa da conta A responder com agente/KB da conta B. Mismatch =>
        # comporta como "sem agente" (nil), nunca 500.
        agent_inbox = ::Autonomia::Agents::AgentInbox.find_by(inbox_id: conversation.inbox_id,
                                                              account_id: conversation.account_id)
        return if agent_inbox.nil?

        agent = agent_inbox.agent
        return unless agent && agent.account_id == conversation.account_id
        return unless agent.enabled? && agent.active?
        return if agent.actuation_internal?
        return if agent.config&.dig('system_key').present?
        return unless test_allowlist_permits?(conversation, agent)

        agent_inbox
      end

      # GUARD-RAIL DE TESTE (aditivo, FAIL-CLOSED). Quando o agente tem
      # `config['test_allowlist_phones']` (lista de números), ele SÓ pode atuar em conversas cujo
      # contato tenha telefone (E.164) batendo — só dígitos — com a lista. Permite testar em caixas
      # reais sem tocar clientes de verdade. Sem a lista => true (comportamento normal, zero
      # regressão). Telefone ausente/não-resolvível => FALSE (nunca responde no escuro; grupos
      # @g.us, com phone_number nil, ficam excluídos automaticamente).
      def self.test_allowlist_permits?(conversation, agent)
        list = Array(agent&.config&.dig('test_allowlist_phones'))
               .map { |phone| phone.to_s.gsub(/\D/, '') }.reject(&:blank?)
        return true if list.empty?

        phone = conversation&.contact&.phone_number.to_s.gsub(/\D/, '')
        return false if phone.blank?

        list.include?(phone)
      end
    end
  end
end
