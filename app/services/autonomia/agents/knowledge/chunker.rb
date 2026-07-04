module Autonomia
  module Agents
    module Knowledge
      # Quebra texto bruto em chunks p/ embedding. Estratégia ESTRUTURADA (P1.1a): segmenta em
      # fronteiras naturais — parágrafos (\n\n, ~= seção heading+corpo), linhas/registros (JSON
      # "chave: valor", XLSX "célula | célula") e itens de lista — gerando UM chunk por unidade
      # estrutural. Unidades MUITO curtas (título órfão, linha solta < MERGE_FLOOR) são coladas na
      # vizinha p/ não virar micro-chunk; unidades maiores que CHUNK_MAX caem na janela deslizante
      # por chars (fallback). Assim um arquivo pequeno multi-tópico vira VÁRIOS chunks mono-tópico
      # (frete / troca / parcelamento / domingo separados) em vez de 1 único embedding diluído — que
      # era a causa do recall-miss (probe: "frete grátis"=0.5038 num chunk-arquivo, descartado).
      # HERANÇA DE CABEÇALHO (P1.1b): o título da seção corrente é PREPENDIDO a cada chunk gerado a
      # partir do corpo da seção — inclusive em cada janela do fallback p/ corpo longo. Sem isso o
      # corpo era fatiado SEM o nome da seção e a busca semântica pelo título só achava o chunk do
      # cabeçalho/sumário, nunca o conteúdo (recall-miss real: "PLUS REASON" em 4 de 2124 chunks).
      # Normaliza whitespace e descarta chunks < MIN_CHUNK chars.
      class Chunker
        MIN_CHUNK = 20
        # Abaixo deste tamanho o chunk acumulado é "pequeno demais p/ ficar sozinho": NÃO fecha,
        # acumula com a próxima unidade (cola título/linha órfã/registro curto ao vizinho) até cruzar
        # o piso. Acima, vira chunk mono-tópico isolado. Calibrado p/ seções curtas de política
        # (frete/troca/parcelamento ~50-90 chars) ficarem cada uma em SEU chunk (recall do sub-tópico).
        MERGE_FLOOR = 45
        # Procura uma fronteira natural nesta janela final do chunk (em chars) antes do corte duro.
        BOUNDARY_LOOKBACK = 200
        BOUNDARIES = ["\n\n", '. ', ".\n", '; ', "\n"].freeze
        # Itens de lista (markdown/numerados) — cada item é uma unidade mono-tópico.
        LIST_ITEM = /\A\s*(?:[-*•]|\d+[.)])\s+/
        # Cabeçalho de seção: unidade curta com cara de título (markdown "#", numeração "47-"/"12."
        # ou linha gritada sem pontuação final). O corpo que vem depois herda esse título em cada
        # chunk, até aparecer o próximo cabeçalho.
        HEADING_MAX = 80
        MARKDOWN_HEADING = /\A\#{1,6}\s+\S/
        NUMBERED_HEADING = /\A\d{1,4}\s*[-–.)]\s*\S/
        TERMINAL_PUNCT = /[.!?:;,]\z/

        # KB-quality Bloco B / B2.2 — palavras-chave por chunk. Espelha Retriever#lexical_terms /
        # STOPWORDS_PT (mesma tokenização) p/ o termo indexado no chunk casar com o termo da query. NÃO
        # importamos do Retriever (arquivo do B3): cópia pequena e comentada evita acoplamento e drift
        # de carga. Se divergir do Retriever, ambos devem ser atualizados juntos.
        KEYWORD_STOPWORDS = %w[para com como qual quais quanto quantos onde quando tem teem voce voces
                               vocês quero sobre nosso nossa email mais menos isso esse essa aqui esta
                               este pelo pela dos das].freeze
        KEYWORD_MIN_LEN = 4
        KEYWORD_MAX = 6

        # Chunk com o texto final (já com herança de cabeçalho) + a metadata determinística do B2.2.
        Chunk = Struct.new(:text, :heading, :keyword_source, keyword_init: true)

        def initialize(text, source_type: nil, max: nil, overlap: nil, merge_floor: nil)
          @text = normalize(text)
          @source_type = source_type
          profile = Autonomia::Agents::Knowledge::ChunkProfile.new(@text, source_type: source_type)
          @material_type = profile.material_type
          # RETROCOMPAT: a chamada legada Chunker.new(text) (SEM source_type) mantém os parâmetros
          # HISTÓRICOS (CHUNK_MAX/CHUNK_OVERLAP) — o sizing adaptativo por perfil só entra quando o
          # chamado informa o source_type (o Ingestor sempre informa). Assim os specs/call-sites
          # antigos não mudam de tamanho, mas o material_type ainda é rotulado p/ a metadata (B2.2).
          params = source_type ? profile.params : Autonomia::Agents::Config::DEFAULT_CHUNK_PROFILE
          @max = max || params[:max]
          @overlap = [overlap || params[:overlap], @max - 1].min
          @merge_floor = merge_floor || params[:merge_floor]
        end

        # Material_type escolhido pelo perfil adaptativo (tabular/faq/list/prose). Exposto p/ o
        # Ingestor carimbar na metadata e p/ specs.
        attr_reader :material_type

        # Array<String> de chunks mono-tópico, ordem preservada do documento. (Retrocompat: chunker_spec
        # e a amostragem do Reviewer chamam .chunks e esperam Strings.)
        def chunks
          build_chunks.map(&:text)
        end

        # KB-quality Bloco B / B2.2 — Array<{ text:, metadata: }>: cada chunk com sua metadata
        # determinística (section_heading, material_type, char_span, keywords). Custo zero (sem IA).
        def chunks_with_metadata
          build_chunks.each_with_index.map do |chunk, index|
            { text: chunk.text, metadata: metadata_for(chunk, index) }
          end
        end

        private

        # Pipeline estrutural único (fonte de verdade p/ chunks e chunks_with_metadata). Devolve
        # Array<Chunk> preservando o cabeçalho da seção corrente de cada pedaço.
        def build_chunks
          return [] if @text.empty?

          result = []
          buffer = +''
          @heading = nil
          units.each do |text, record|
            buffer = if heading?(text, record)
                       open_section(result, buffer, text)
                     elsif text.length > @max
                       emit_long_unit(result, buffer, text)
                     else
                       accumulate(result, buffer, text, record)
                     end
          end
          flush(result, buffer)
          result
        end

        # Metadata determinística do chunk (B2.2). keyword_source = texto ORIGINAL do chunk (sem o
        # cabeçalho prefixado) p/ as keywords refletirem o conteúdo, não o título repetido.
        def metadata_for(chunk, index)
          {
            section_heading: chunk.heading,
            material_type: @material_type.to_s,
            chunk_index: index,
            char_span: chunk.text.length,
            keywords: keywords_for(chunk.keyword_source)
          }
        end

        # Top KEYWORD_MAX termos de conteúdo (>= KEYWORD_MIN_LEN, sem stopwords PT), dedup, ordem de
        # aparição. Mesma tokenização do Retriever#lexical_terms (casamento léxico query↔chunk).
        def keywords_for(text)
          text.to_s.downcase.scan(/[\p{Alnum}]{#{KEYWORD_MIN_LEN},}/o)
              .reject { |w| KEYWORD_STOPWORDS.include?(w) }.uniq.first(KEYWORD_MAX)
        end

        # Novo cabeçalho fecha a seção anterior (se o acumulado já pode virar chunk; senão segue
        # acumulando p/ não descartar linha curta) e abre o buffer da nova seção com o título —
        # assim o primeiro chunk do corpo já nasce com ele, sem precisar prepender.
        def open_section(result, buffer, text)
          buffer = flush(result, buffer) if buffer.strip.length >= MIN_CHUNK
          @heading = text
          append(buffer, text)
        end

        # Título recém-visto ainda sozinho no buffer NÃO vira chunk órfão: ele será herdado por
        # cada janela do corpo longo abaixo (era o recall-miss: corpo fatiado sem título).
        def emit_long_unit(result, buffer, text)
          buffer = +'' if @heading && buffer.strip == @heading
          flush(result, buffer)
          result.concat(split_long_unit(text))
          +''
        end

        # Só fecha quando o acumulado já é substancial (>= MIN_CHUNK): registro tabular/lista
        # (JSON/XLSX/itens) vira 1 chunk por registro; parágrafo de prosa fecha ao cruzar o piso
        # de merge. Buffer ainda curto (título solto, registro de poucos chars) NÃO é descartado —
        # segue acumulando na próxima unidade (evita perder linha-registro curta).
        def accumulate(result, buffer, text, record)
          buffer = append(buffer, text)
          threshold = record ? MIN_CHUNK : @merge_floor
          buffer.strip.length >= threshold ? flush(result, buffer) : buffer
        end

        def append(buffer, text)
          buffer << "\n" unless buffer.empty?
          buffer << text
        end

        def normalize(text)
          text.to_s.gsub("\r\n", "\n").gsub(/[ \t]+/, ' ').gsub(/\n{3,}/, "\n\n").strip
        end

        # Empilha o buffer corrente como Chunk (se atinge MIN_CHUNK), herdando o cabeçalho da seção
        # corrente quando o texto ainda não o contém, e devolve um buffer limpo. keyword_source guarda
        # o corpo ORIGINAL (sem o título prefixado) p/ as keywords (B2.2) refletirem o conteúdo.
        def flush(result, buffer)
          body = buffer.strip
          return +'' if body.empty?

          text = inherit_heading(body)
          result << Chunk.new(text: text, heading: @heading, keyword_source: body) if text.length >= MIN_CHUNK
          +''
        end

        # Prependa o título da seção corrente ao chunk — a menos que o texto já o contenha
        # (primeiro chunk da seção nasce com o título no buffer; não duplicar).
        def inherit_heading(chunk)
          # start_with?, não include?: só evita duplicar quando o título já ABRE o
          # chunk (primeiro chunk da seção). Título que apareça no meio do corpo
          # não impede o prefixo de contexto no início.
          return chunk if @heading.nil? || chunk.start_with?(@heading)

          "#{@heading}\n#{chunk}"
        end

        # Pergunta de FAQ extraída do fim de um segmento corrido: a última sentença terminando em "?"
        # (8..180 chars, sem cruzar pontuação de sentença anterior). Vira o "cabeçalho" do par P+R.
        FAQ_QUESTION_TAIL = /[^.!?\n]{8,180}[ \t]*\?\z/

        def heading?(text, record)
          # Fix GTA 2026-07-04: em material FAQ, a PERGUNTA é o cabeçalho da seção — a resposta herda a
          # pergunta em todo chunk (inclusive respostas longas fatiadas), e section_heading deixa de sair
          # vazio. Era o recall-miss do estilo P+R: janela cega cortava resposta longe da sua pergunta.
          return true if record == :question
          return false if record || text.length > HEADING_MAX
          return true if text.match?(MARKDOWN_HEADING)
          # Numeração ("47-", "12.") só é título se NÃO terminar em pontuação de
          # frase — senão item de lista/instrução ("1. Escolha a opção.") viraria
          # falso título e poluiria os chunks seguintes com prefixo errado.
          return true if text.match?(NUMBERED_HEADING) && !text.match?(TERMINAL_PUNCT)

          shouted_line?(text)
        end

        # Linha "gritada" (sem minúsculas, sem pontuação final) tem cara de título de seção de
        # PDF/apólice. Linha curta em caixa normal NÃO é título — segue sendo seção mono-tópico
        # própria (frete/troca/parcelamento), preservando a calibração do MERGE_FLOOR.
        def shouted_line?(text)
          text.match?(/[[:alpha:]]/) && !text.match?(/[[:lower:]]/) && !text.match?(TERMINAL_PUNCT)
        end

        # Unidades estruturais primárias como pares [texto, record?]: parágrafos (\n\n); dentro de um
        # parágrafo tabular/registro (JSON "chave: valor", XLSX "a | b", lista), cada LINHA é uma
        # unidade-registro (record=true → 1 chunk por registro). Prosa contínua fica inteira
        # (record=false → acumula até o piso).
        def units
          @text.split(/\n{2,}/).flat_map { |para| split_paragraph(para) }.reject { |text, _| text.strip.empty? }
        end

        def split_paragraph(para)
          return faq_units(para) if @material_type == :faq

          lines = para.split("\n").map(&:strip).reject(&:empty?)
          return [[para.strip, false]] if lines.size <= 1

          record_lines?(lines) ? lines.map { |line| [line, true] } : [[lines.join(' '), false]]
        end

        # Fix GTA 2026-07-04 — material FAQ: quebra o parágrafo NAS PERGUNTAS (mesmo em texto corrido
        # de PDF, sem quebras de linha). Cada segmento que termina em "?" fecha na pergunta: o rabo
        # vira unidade :question (→ cabeçalho da seção via heading?); o que vem antes dela é resto da
        # RESPOSTA anterior (unidade comum). Resultado: chunk = "Pergunta?\nResposta…" — a resposta
        # nunca nasce órfã da pergunta, e a busca pela pergunta acha a resposta.
        def faq_units(para)
          para.split(/(?<=\?)\s+/).flat_map do |segment|
            segment = segment.strip
            next [] if segment.empty?
            next [[segment, false]] unless segment.end_with?('?')

            question = segment[FAQ_QUESTION_TAIL] || segment
            lead = segment[0...-question.length].strip
            units = []
            units << [lead, false] unless lead.empty?
            units << [question.strip, :question]
          end
        end

        # Heurística barata: o parágrafo é "tabular/registro" se a maioria das linhas tem cara de
        # registro — separador de célula " | " (XLSX), "chave: valor" (JSON) ou item de lista.
        def record_lines?(lines)
          hits = lines.count do |line|
            line.include?(' | ') || line =~ /\A[^:\n]{1,60}:\s/ || line =~ LIST_ITEM
          end
          hits >= (lines.size / 2.0).ceil
        end

        # Fallback p/ unidade única acima de CHUNK_MAX: janela deslizante por chars com overlap,
        # quebrando em fronteira natural próxima ao fim da janela (lógica original do chunker).
        # CADA janela herda o cabeçalho da seção corrente; a janela encolhe pelo tamanho do título
        # p/ o chunk final (título + pedaço) não estourar @max.
        def split_long_unit(unit)
          reserve = @heading ? @heading.length + 1 : 0
          window = [@max - reserve, MIN_CHUNK].max
          pieces = []
          cursor = 0
          length = unit.length
          while cursor < length
            stop = boundary_stop(unit, cursor, [cursor + window, length].min, length)
            piece = unit[cursor...stop].strip
            pieces << Chunk.new(text: inherit_heading(piece), heading: @heading, keyword_source: piece) if piece.length >= MIN_CHUNK
            break if stop >= length

            cursor = [stop - @overlap, cursor + 1].max
          end
          pieces
        end

        # Tenta terminar o chunk numa fronteira natural dentro dos últimos BOUNDARY_LOOKBACK chars;
        # senão corta no limite duro.
        def boundary_stop(text, start, hard_stop, length)
          return hard_stop if hard_stop >= length

          window_start = [hard_stop - BOUNDARY_LOOKBACK, start + MIN_CHUNK].max
          best = BOUNDARIES.filter_map do |sep|
            idx = text.rindex(sep, hard_stop - 1)
            idx + sep.length if idx && idx >= window_start
          end.max
          best || hard_stop
        end
      end
    end
  end
end
