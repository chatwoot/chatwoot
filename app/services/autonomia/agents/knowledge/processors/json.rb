module Autonomia
  module Agents
    module Knowledge
      module Processors
        # json: JSON.parse e achatamento em texto plano p/ embeddings, agrupando por ENTRADA
        # (P1.1a/P1.2). Cada objeto de um array/objeto (ex.: um produto, uma FAQ) vira UMA linha
        # estilo XLSX com TODOS os seus campos-folha juntos (`Notebook Pro 15 | sku NB-15 | preco
        # 4999 | garantia 12 meses`), em vez de 1 linha por campo-folha. Assim o Chunker (que fecha
        # 1 chunk por linha-registro) mantém o fato composto (nome<->preço, Q<->A) num chunk único —
        # sem isso "Quanto custa o Notebook Pro 15" recuperaria o nome SEM o preço. Escalares de topo
        # (loja, empresa) ficam cada um em sua linha "chave: valor"; arrays de escalares viram uma
        # linha "chave: a, b, c".
        class Json < Base
          def extract
            raw = download_bytes.to_s.force_encoding('UTF-8')
            data = JSON.parse(raw)
            lines(data).reject(&:empty?).join("\n")
          rescue JSON::ParserError => e
            raise ExtractionError, "invalid_json: #{e.message}"
          end

          private

          # Array<String>: uma linha por ENTRADA (objeto) ou por escalar de topo.
          def lines(node, label = nil)
            case node
            when Hash then hash_lines(node, label)
            when Array then array_lines(node, label)
            else [prefixed(label, node.to_s)]
            end
          end

          def hash_lines(hash, label)
            simple, nested = hash.partition { |_, value| scalar?(value) || scalar_array?(value) }
            entry = simple.map { |key, value| entry_field(key, value) }
            head = entry.any? ? [prefixed(label, entry.join(' | '))] : []
            head + nested.flat_map { |key, value| lines(value, join_key(label, key)) }
          end

          def array_lines(array, label)
            scalar_array?(array) ? [prefixed(label, array.join(', '))] : array.flat_map { |value| lines(value, label) }
          end

          # Campo-folha dentro de uma entrada: "chave valor" (XLSX-like, sem ':' p/ não disparar
          # múltiplos registros na mesma linha). Escalares aninhados raros caem como texto plano.
          def entry_field(key, value)
            value = value.join(', ') if value.is_a?(Array)
            "#{key} #{value}"
          end

          def prefixed(label, text)
            label.to_s.empty? ? text : "#{label}: #{text}"
          end

          def scalar?(value)
            !value.is_a?(Hash) && !value.is_a?(Array)
          end

          def scalar_array?(value)
            value.is_a?(Array) && value.all? { |v| scalar?(v) }
          end

          def join_key(prefix, key)
            prefix.to_s.empty? ? key.to_s : "#{prefix}.#{key}"
          end
        end
      end
    end
  end
end
