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

        def initialize(text, max: Config::CHUNK_MAX, overlap: Config::CHUNK_OVERLAP, merge_floor: MERGE_FLOOR)
          @text = normalize(text)
          @max = max
          @overlap = [overlap, max - 1].min
          @merge_floor = merge_floor
        end

        # Array<String> de chunks mono-tópico, ordem preservada do documento.
        def chunks
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

        private

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

        # Empilha o buffer corrente como chunk (se atinge MIN_CHUNK), herdando o cabeçalho da seção
        # corrente quando o texto ainda não o contém, e devolve um buffer limpo.
        def flush(result, buffer)
          chunk = buffer.strip
          return +'' if chunk.empty?

          chunk = inherit_heading(chunk)
          result << chunk if chunk.length >= MIN_CHUNK
          +''
        end

        # Prependa o título da seção corrente ao chunk — a menos que o texto já o contenha
        # (primeiro chunk da seção nasce com o título no buffer; não duplicar).
        def inherit_heading(chunk)
          return chunk if @heading.nil? || chunk.include?(@heading)

          "#{@heading}\n#{chunk}"
        end

        def heading?(text, record)
          return false if record || text.length > HEADING_MAX
          return true if text.match?(MARKDOWN_HEADING) || text.match?(NUMBERED_HEADING)

          # Linha "gritada" (sem minúsculas, sem pontuação final) tem cara de título de seção de
          # PDF/apólice. Linha curta em caixa normal NÃO é título — segue sendo seção mono-tópico
          # própria (frete/troca/parcelamento), preservando a calibração do MERGE_FLOOR.
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
          lines = para.split("\n").map(&:strip).reject(&:empty?)
          return [[para.strip, false]] if lines.size <= 1

          record_lines?(lines) ? lines.map { |line| [line, true] } : [[lines.join(' '), false]]
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
            pieces << inherit_heading(piece) if piece.length >= MIN_CHUNK
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
