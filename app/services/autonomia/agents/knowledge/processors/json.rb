module Autonomia
  module Agents
    module Knowledge
      module Processors
        # json: JSON.parse e ACHATAMENTO da árvore em linhas "path.to.key: value" (uma por folha),
        # p/ que cada folha vire um registro mono-tópico — o Chunker reconhece "chave: valor" como
        # linha-registro e fecha 1 chunk por registro. Objetos aninhados viram prefixo pontuado
        # (`endereco.cidade: ...`); arrays viram índice no path (`itens.0.sku: ...`). Escalares de um
        # array simples são agrupados numa única linha "chave: a, b, c". Arrays grandes são LIMITADOS
        # a ARRAY_CAP itens (evita explodir o texto em catálogos enormes), anexando uma linha de nota.
        class Json < Base
          # Teto de itens percorridos por array de objetos/aninhados. Além disso, uma linha
          # "path: (+N itens omitidos)" sinaliza o corte p/ não mascarar dados faltantes.
          ARRAY_CAP = 200

          def extract
            raw = download_bytes.to_s.force_encoding('UTF-8')
            data = JSON.parse(raw)
            flatten(data).reject(&:empty?).join("\n")
          rescue JSON::ParserError => e
            raise ExtractionError, "invalid_json: #{e.message}"
          end

          private

          # Array<String>: uma linha "path: valor" por folha. `path` é o caminho pontuado até a folha.
          def flatten(node, path = nil)
            case node
            when Hash then hash_lines(node, path)
            when Array then array_lines(node, path)
            else [line(path, node.to_s)]
            end
          end

          def hash_lines(hash, path)
            hash.flat_map { |key, value| flatten(value, join_key(path, key)) }
          end

          # Array de escalares -> uma linha "path: a, b, c". Array com objetos/aninhados -> índice no
          # path, limitado a ARRAY_CAP itens (com nota de corte).
          def array_lines(array, path)
            return [line(path, array.join(', '))] if scalar_array?(array)

            capped = array.take(ARRAY_CAP)
            lines = capped.each_with_index.flat_map { |value, index| flatten(value, join_key(path, index)) }
            array.size > ARRAY_CAP ? lines + [line(path, "(+#{array.size - ARRAY_CAP} itens omitidos)")] : lines
          end

          def line(path, value)
            path.to_s.empty? ? value : "#{path}: #{value}"
          end

          def scalar?(value)
            !value.is_a?(Hash) && !value.is_a?(Array)
          end

          def scalar_array?(value)
            value.is_a?(Array) && value.any? && value.all? { |v| scalar?(v) }
          end

          def join_key(prefix, key)
            prefix.to_s.empty? ? key.to_s : "#{prefix}.#{key}"
          end
        end
      end
    end
  end
end
