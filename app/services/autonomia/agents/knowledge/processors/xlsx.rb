module Autonomia
  module Agents
    module Knowledge
      module Processors
        # xlsx: leitura de planilha via gem `roo` -> linhas em texto CSV-like (uma linha por linha
        # da planilha, células separadas por " | "). A gem é opcional neste fork — se ausente,
        # degrada p/ UnsupportedFormat (fonte vira `failed`), sem bloquear o release.
        class Xlsx < Base
          def extract
            ensure_gem!
            # rescue de Roo/Zip só DEPOIS do ensure_gem!: com a gem ausente, ensure_gem! levanta
            # UnsupportedFormat e as constantes `Roo`/`Zip` (indefinidas) não são avaliadas.
            begin
              blocks = []
              with_tempfile do |path|
                book = Roo::Spreadsheet.open(path, extension: :xlsx)
                book.sheets.each { |sheet| blocks.concat(block_for(book, sheet)) }
              end
              blocks.join("\n")
            rescue Roo::Error, Zip::Error => e
              raise ExtractionError, "xlsx_parse_failed: #{e.message}"
            end
          end

          private

          # Bloco de uma aba: cabeçalho markdown com o NOME DA ABA (o Chunker reconhece "## x" como
          # heading e o herda em cada chunk do corpo -> preserva o contexto da aba) seguido das
          # linhas. Aba vazia é ignorada (não polui com heading sem corpo).
          def block_for(book, sheet)
            rows = rows_for(book, sheet)
            return [] if rows.empty?

            ["## #{sheet}", *rows]
          end

          def rows_for(book, sheet)
            book.sheet(sheet).to_a.filter_map do |row|
              cells = row.map { |cell| cell.to_s.strip }.reject(&:empty?)
              cells.join(' | ') if cells.any?
            end
          end

          def ensure_gem!
            require 'roo'
          rescue LoadError
            raise UnsupportedFormat, 'xlsx_support_unavailable'
          end
        end
      end
    end
  end
end
