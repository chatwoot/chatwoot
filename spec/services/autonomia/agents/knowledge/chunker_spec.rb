require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Chunker do
  let(:chunk_max) { Autonomia::Agents::Config::CHUNK_MAX }

  describe '#chunks' do
    context 'when a section has a short heading followed by a body longer than CHUNK_MAX' do
      it 'prepends the heading to every chunk generated from the body' do
        # Arrange
        heading = 'POLITICA DE REEMBOLSO'
        sentence = 'O reembolso e processado em ate trinta dias uteis apos a solicitacao formal do cliente. '
        body = sentence * 20 # ~1780 chars, bem acima de CHUNK_MAX
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks.size).to be > 1
        expect(chunks).to all(start_with(heading))
      end
    end

    context 'when the first body chunk already contains the heading' do
      it 'does not duplicate the heading' do
        # Arrange
        heading = '47- CANCELAMENTO DE VIAGEM PLUS REASON'
        body = 'Garante reembolso caso o segurado precise cancelar a viagem por motivo imprevisto.'
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks.size).to eq(1)
        expect(chunks.first.scan(heading).size).to eq(1)
        expect(chunks.first).to start_with(heading)
      end
    end

    context 'with a tabular/record paragraph and no heading' do
      it 'keeps emitting one chunk per record, unchanged' do
        # Arrange
        records = [
          'Nome: Joao Silva de Souza',
          'Cargo: Analista de Suporte',
          'Cidade: Sao Paulo capital'
        ]
        document = records.join("\n")

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks).to eq(records)
      end
    end

    context 'with a prose document without headings' do
      it 'keeps the original one-chunk-per-paragraph behavior' do
        # Arrange
        paragraphs = [
          'O frete gratis vale para compras acima de noventa e nove reais em todo o Brasil.',
          'As trocas podem ser feitas em ate trinta dias corridos apos o recebimento do pedido.'
        ]
        document = paragraphs.join("\n\n")

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks).to eq(paragraphs)
      end
    end

    context 'with the real policy section (numbered heading + body over 2x CHUNK_MAX)' do
      it 'makes the section name searchable in every body chunk without exceeding CHUNK_MAX' do
        # Arrange
        heading = '47- CANCELAMENTO DE VIAGEM PLUS REASON'
        motive = 'Morte do segurado ou de parentes proximos comprovada por documento oficial emitido em cartorio. '
        body = motive * 15 # ~1470 chars, acima de 2x CHUNK_MAX (600)
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(body.length).to be > (2 * chunk_max)
        expect(chunks.size).to be >= 3
        expect(chunks).to all(include('PLUS REASON'))
        expect(chunks.map { |chunk| chunk.scan(heading).size }).to all(eq(1))
        expect(chunks.map(&:length)).to all(be <= chunk_max)
      end
    end
  end

  it 'does not treat a numbered list sentence as a section heading' do
    body = 'x' * 700
    text = "1. Escolha a opcao desejada.\n\n#{body}"
    chunks = described_class.new(text).chunks
    expect(chunks).to all(satisfy { |c| !c.start_with?('1. Escolha a opcao desejada.') || c == '1. Escolha a opcao desejada.' })
    expect(chunks.any? { |c| c.include?('1. Escolha a opcao desejada.') && c.include?('x' * 50) }).to be(false)
  end

  it 'inherits a heading that legitimately reappears in the body' do
    heading = '47- CANCELAMENTO PLUS REASON'
    body = "motivo A. #{heading} tambem cobre. " + ('detalhe ' * 120)
    chunks = described_class.new("#{heading}\n\n#{body}").chunks
    expect(chunks).to all(start_with(heading))
  end

  # B2.1 — perfil ADAPTATIVO: o material_type escolhe o teto de janela por tipo/estilo.
  describe 'adaptive chunk profile (B2.1)' do
    it 'classifies a xlsx source as tabular and keeps the small (300) window' do
      # Arrange — xlsx é tabular por natureza (independe do conteúdo).
      chunker = described_class.new('Coluna A | Coluna B', source_type: 'xlsx')

      # Assert
      expect(chunker.material_type).to eq(:tabular)
      expect(chunker.send(:instance_variable_get, :@max)).to eq(300)
    end

    it 'classifies continuous prose as prose and uses the large (900) window' do
      # Arrange — parágrafos contínuos, sem registros/bullets/FAQ.
      prose = 'O reembolso e processado em ate trinta dias uteis apos a solicitacao formal.'
      chunker = described_class.new("#{prose}\n\n#{prose}", source_type: 'pdf')

      # Assert
      expect(chunker.material_type).to eq(:prose)
      expect(chunker.send(:instance_variable_get, :@max)).to eq(900)
    end

    it 'classifies a P:/R: document as faq' do
      # Arrange
      faq = "P: Voces entregam no domingo?\nR: Sim, das oito as doze horas.\n" \
            "P: Qual o prazo de troca?\nR: Trinta dias corridos apos o recebimento."
      chunker = described_class.new(faq, source_type: 'txt')

      # Assert
      expect(chunker.material_type).to eq(:faq)
      expect(chunker.send(:instance_variable_get, :@max)).to eq(700)
    end

    it 'gives prose a larger window than tabular for the SAME long body' do
      # Arrange — um corpo de prosa acima de 900 chars: perfil prose fatia em MENOS pedaços
      # (janela 900) que o perfil tabular default (janela 300) — chunks de tamanhos variados.
      sentence = 'O reembolso e processado em ate trinta dias uteis apos a solicitacao formal. '
      body = sentence * 20 # ~1560 chars
      prose_chunks = described_class.new(body, source_type: 'pdf').chunks
      tabular_chunks = described_class.new(body, source_type: 'xlsx').chunks

      # Assert
      expect(prose_chunks.size).to be < tabular_chunks.size
    end
  end

  # B2.2 — metadata determinística por chunk (custo zero).
  describe '#chunks_with_metadata (B2.2)' do
    it 'returns the section_heading, material_type and keywords per chunk' do
      # Arrange
      heading = 'POLITICA DE REEMBOLSO'
      body = 'O reembolso integral e processado em ate trinta dias uteis para o cliente.'
      document = "#{heading}\n\n#{body}"

      # Act
      entries = described_class.new(document, source_type: 'pdf').chunks_with_metadata

      # Assert
      expect(entries).to all(include(:text, :metadata))
      meta = entries.first[:metadata]
      expect(meta[:section_heading]).to eq(heading)
      expect(meta[:material_type]).to eq('prose')
      expect(meta[:char_span]).to eq(entries.first[:text].length)
      expect(meta[:keywords]).to include('reembolso', 'trinta')
    end

    it 'derives keywords from the body, not from the inherited heading, and drops stopwords' do
      # Arrange — "sobre" e "para" sao stopwords; "reembolso" tem >= 4 chars.
      entries = described_class.new('Regras sobre o reembolso para o cliente final.', source_type: 'txt')
                               .chunks_with_metadata

      # Assert
      keywords = entries.first[:metadata][:keywords]
      expect(keywords).to include('reembolso', 'regras', 'cliente')
      expect(keywords).not_to include('sobre', 'para')
    end
  end

  # Retrocompat — .chunks continua devolvendo Strings (Reviewer sampling + specs antigos).
  it 'keeps #chunks returning plain strings (backward compat)' do
    chunks = described_class.new('Um paragrafo simples de prosa para o cliente.', source_type: 'txt').chunks
    expect(chunks).to all(be_a(String))
  end

  # Fix GTA 2026-07-04 - FAQ em texto corrido de PDF: perfil por densidade de "?" + par P+R por chunk.
  describe 'flowing-PDF FAQ (question density)' do
    let(:qa_text) do
      'O que podemos considerar como urgencia e emergencia? Considera-se emergencia a situacao onde o ' \
        'segurado necessita de atendimento imediato por risco de vida constatado por profissional. ' \
        'O seguro cobre COVID? Sim, sera autorizado o atendimento medico e hospitalar ao passageiro ate o ' \
        'limite estabelecido do plano contratado na apolice vigente. ' \
        'Como aciono a assistencia em viagem? Ligue para a central de atendimento com o numero da apolice ' \
        'em maos, a qualquer hora do dia, em portugues ou ingles. ' \
        'Qual o prazo para reembolso? Trinta dias uteis apos a entrega completa dos documentos exigidos ' \
        'pela seguradora conforme as condicoes gerais. ' \
        'Quem pode ser beneficiario do seguro? Qualquer pessoa fisica indicada pelo titular no momento da ' \
        'contratacao do plano de viagem.'
    end

    it 'classifies flowing question-dense text as faq (line signature never fires)' do
      expect(described_class.new(qa_text, source_type: 'pdf').material_type).to eq(:faq)
    end

    it 'keeps each answer attached to its question and uses the question as section_heading' do
      # Act
      entries = described_class.new(qa_text, source_type: 'pdf').chunks_with_metadata

      # Assert - o chunk do COVID contem pergunta E resposta juntas; heading = a pergunta
      covid = entries.find { |e| e[:text].include?('COVID') }
      expect(covid[:text]).to include('O seguro cobre COVID?')
      expect(covid[:text]).to include('Sim, sera autorizado')
      expect(covid[:metadata][:section_heading]).to eq('O seguro cobre COVID?')
      expect(covid[:metadata][:material_type]).to eq('faq')
    end
  end

  # Codex HIGH #118: pergunta longa (>180 chars) fica INTEIRA no heading; o comeco dela nao vaza
  # como "resposta" do par anterior.
  describe 'long FAQ question (no 180-char cap)' do
    it 'keeps the whole long question as the section_heading of its own pair' do
      # Arrange - 5 perguntas p/ densidade; a quarta e LONGA (>180 chars)
      long_q = 'Em quais situacoes de emergencia medica ocorridas durante a viagem internacional o ' \
               'segurado tem direito ao reembolso integral das despesas hospitalares e farmaceuticas ' \
               'previstas nas condicoes gerais da apolice contratada?'
      text = 'Voces entregam no domingo? Sim, das oito as doze horas em todo o territorio nacional. ' \
             'Qual o prazo de troca? Trinta dias corridos apos o recebimento do produto pelo cliente. ' \
             'O seguro cobre COVID? Sim, ate o limite estabelecido do plano contratado na apolice. ' \
             "#{long_q} O reembolso integral e devido sempre que a rede credenciada nao estiver disponivel. " \
             'Quem pode ser beneficiario? Qualquer pessoa fisica indicada pelo titular na contratacao.'

      # Act
      entries = described_class.new(text, source_type: 'pdf').chunks_with_metadata

      # Assert
      expect(long_q.length).to be > 180
      pair = entries.find { |e| e[:metadata][:section_heading].to_s.include?('reembolso integral das despesas') }
      expect(pair[:metadata][:section_heading]).to eq(long_q)
      expect(pair[:text]).to include('sempre que a rede credenciada')
      covid = entries.find { |e| e[:text].include?('COVID') }
      expect(covid[:text]).not_to include('Em quais situacoes de emergencia')
    end
  end
end
