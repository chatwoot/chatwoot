module Autonomia
  module Agents
    # "Copiloto" — sugestão de rascunho ao ATENDENTE humano (não ao cliente final). Reusa o
    # Answerer. Diferença semântica do Testar: SEMPRE devolve um `reply` mesmo sob handoff (o
    # humano revisa). Quando o portão de confiança suprime o `reply` (handoff com fallback nil),
    # cai no `raw_reply` — o melhor esforço do modelo antes do portão (conteúdo gerado, não é IP).
    # NUNCA expõe instruction/scaffold/prompt; o jbuilder /suggest filtra a fronteira de segurança.
    class Copilot
      def initialize(agent:, message:, history: [], retrieval_query: nil)
        @agent = agent
        @message = message
        @history = history
        @retrieval_query = retrieval_query
      end

      # -> Autonomia::Agents::AnswerResult (com reply garantido p/ o atendente revisar)
      def suggest
        # AUDIÊNCIA = :customer. O rascunho do copiloto é texto CLIENTE-FACING: ele é inserido direto no
        # composer de resposta ao cliente (ConversationCopilot#draft_reply, widget reply_suggestion). Por
        # isso NÃO usamos :attendant aqui (geraria meta-texto "sugestão ao atendente" no campo do cliente).
        # A regra anti-"material" universal do v2 já vale p/ :customer, então o copiloto interno também
        # não cita "material" (decisão do PO). :attendant fica reservado p/ um copiloto analítico futuro.
        Answerer.new(agent: @agent, query: @message, history: @history, audience: :customer,
                     retrieval_query: @retrieval_query).answer
      end
    end
  end
end
