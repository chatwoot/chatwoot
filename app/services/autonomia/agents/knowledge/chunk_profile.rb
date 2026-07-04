module Autonomia
  module Agents
    module Knowledge
      # KB-quality Bloco B / B2.1 — Escolhe o PERFIL de chunking (tamanho da janela, overlap, piso de
      # merge) por TIPO/ESTILO do material. Combina o source_type (sinal barato do formato) com uma
      # ASSINATURA de conteúdo determinística (amostra do texto) — sem custo de IA. A ideia (pedido do
      # PO): "chunks de tamanhos variados de acordo com o tipo do material". Um PDF de política (prosa
      # contínua) merece janela grande p/ não picar a seção; um XLSX/JSON de registros merece 1
      # registro por chunk; um FAQ merece 1 par P+R; um procedimento merece 1 passo por chunk.
      #
      # material_type ∈ {tabular, faq, list, prose}. O Chunker usa os parâmetros; o material_type
      # também vai para a metadata de cada chunk (B2.2), tornando o chunk mais "encontrável".
      class ChunkProfile
        MATERIAL_TYPES = %i[tabular faq list prose].freeze

        # Fração das linhas que precisa "ter cara de X" p/ o documento inteiro virar aquele perfil.
        SIGNATURE_THRESHOLD = 0.5
        # Amostra barata: só as primeiras N linhas não-vazias bastam p/ assinar o estilo do documento.
        SAMPLE_LINES = 60

        # Linha-registro tabular: separador de célula XLSX (" | ") ou "chave: valor" curto (JSON/planilha).
        RECORD_LINE = /\A[^:\n]{1,60}:\s|\s\|\s/
        # Item de lista/procedimento (markdown ou numerado).
        LIST_LINE = /\A\s*(?:[-*•]|\d+[.)])\s+/
        # Marcadores de FAQ: "P:"/"R:", "Pergunta:"/"Resposta:" ou linha que termina em "?" (a pergunta).
        FAQ_LINE = /\A\s*(?:P|R|Pergunta|Resposta)\s*[:.\-)]\s|\?\s*\z/i

        # source_types que já são tabulares por natureza — assinatura forte independente do conteúdo.
        TABULAR_SOURCE_TYPES = %w[xlsx json].freeze

        # FAQ por DENSIDADE de perguntas (fix GTA 2026-07-04): PDF de condições gerais em estilo
        # pergunta/resposta sai da extração como texto CORRIDO ("… urgência e emergência ? Considera-se: …")
        # — a assinatura por LINHA (FAQ_LINE) nunca dispara (nenhuma linha termina em "?") e o doc caía em
        # :prose (1931/1931 chunks da conta 3). Sinal complementar: muitos "?" no corpo = FAQ, mesmo sem
        # quebra de linha. Limiares conservadores p/ prosa normal (com "?" esporádico) seguir :prose.
        QUESTION_SAMPLE_CHARS = 6000
        QUESTION_MIN_COUNT = 5
        QUESTION_MIN_DENSITY = 1.0 / 800 # >= 1 pergunta a cada ~800 chars da amostra

        def initialize(text, source_type: nil)
          @text = text.to_s
          @source_type = source_type.to_s
        end

        # Símbolo do perfil escolhido (tabular/faq/list/prose).
        def material_type
          @material_type ||= detect
        end

        # Hash de parâmetros do Chunker p/ este material (max/overlap/merge_floor).
        def params
          Autonomia::Agents::Config::CHUNK_PROFILES.fetch(material_type, Autonomia::Agents::Config::DEFAULT_CHUNK_PROFILE)
        end

        private

        # Ordem de precedência: FAQ e tabular são assinaturas fortes; lista vem depois (um FAQ pode ter
        # bullets); prosa é o default quando nada assina claramente.
        def detect
          return :tabular if TABULAR_SOURCE_TYPES.include?(@source_type)

          lines = sample_lines
          return :prose if lines.empty?

          return :faq     if signature?(lines, FAQ_LINE) || question_dense?
          return :tabular if signature?(lines, RECORD_LINE)
          return :list    if signature?(lines, LIST_LINE)

          :prose
        end

        def sample_lines
          @text.split("\n").map(&:strip).reject(&:empty?).first(SAMPLE_LINES)
        end

        # FAQ em texto corrido (PDF): a amostra tem perguntas em quantidade E densidade — "?" esporádico
        # de prosa comum não dispara nenhum dos dois limiares juntos.
        def question_dense?
          sample = @text[0, QUESTION_SAMPLE_CHARS].to_s
          return false if sample.empty?

          questions = sample.count('?')
          questions >= QUESTION_MIN_COUNT && (questions.to_f / sample.length) >= QUESTION_MIN_DENSITY
        end

        def signature?(lines, pattern)
          hits = lines.count { |line| line.match?(pattern) }
          hits >= (lines.size * SIGNATURE_THRESHOLD).ceil
        end
      end
    end
  end
end
