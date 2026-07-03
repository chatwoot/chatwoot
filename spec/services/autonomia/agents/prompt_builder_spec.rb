require 'rails_helper'

RSpec.describe Autonomia::Agents::PromptBuilder do
  let(:agent) { Autonomia::Agents::Agent.new(name: 'Agente', agent_type: 'custom') }

  def build(query: 'oi', history: [])
    described_class.new(agent: agent, query: query, history: history)
  end

  def text_of(message)
    message[:content].first[:text]
  end

  describe 'query truncation (C1)' do
    it 'truncates an oversized query from the end and marks the cut with the suffix' do
      # Arrange
      query = 'a' * (Autonomia::Agents::Config::MAX_COMPOSED_QUERY_CHARS + 5_000)

      # Act
      sent = text_of(build(query: query).input.last)

      # Assert
      expect(sent.length).to eq(Autonomia::Agents::Config::MAX_COMPOSED_QUERY_CHARS)
      expect(sent).to end_with(Autonomia::Agents::Config::TRUNCATION_SUFFIX)
      expect(sent).to start_with('aaa')
    end

    it 'keeps a query within the cap untouched' do
      # Arrange
      query = 'pergunta curta do cliente'

      # Act
      sent = text_of(build(query: query).input.last)

      # Assert
      expect(sent).to eq(query)
    end
  end

  describe 'history caps (C1)' do
    it 'truncates each history item to MAX_HISTORY_ITEM_CHARS keeping the beginning' do
      # Arrange
      big = "inicio-#{'x' * Autonomia::Agents::Config::MAX_HISTORY_ITEM_CHARS}"
      history = [{ role: 'user', content: big }]

      # Act
      sent = text_of(build(history: history).input.first)

      # Assert
      expect(sent.length).to eq(Autonomia::Agents::Config::MAX_HISTORY_ITEM_CHARS)
      expect(sent).to start_with('inicio-')
      expect(sent).to end_with(Autonomia::Agents::Config::TRUNCATION_SUFFIX)
    end

    it 'keeps only the most recent items within the MAX_HISTORY_TOTAL_CHARS budget' do
      # Arrange: 10 itens no teto por item (4k) contra um orçamento total de 24k -> só os 6 últimos cabem
      item_size = Autonomia::Agents::Config::MAX_HISTORY_ITEM_CHARS
      fitting = Autonomia::Agents::Config::MAX_HISTORY_TOTAL_CHARS / item_size
      history = Array.new(10) { |i| { role: 'user', content: format('%03d', i) + ('x' * item_size) } }

      # Act
      messages = build(history: history).input[0..-2] # tudo menos a query final

      # Assert
      expect(messages.size).to eq(fitting)
      expect(text_of(messages.first)).to start_with(format('%03d', 10 - fitting)) # mais antigos descartados
      expect(text_of(messages.last)).to start_with('009')                         # mais recente preservado
    end

    it 'keeps a short history fully intact' do
      # Arrange
      history = [{ role: 'user', content: 'oi' }, { role: 'assistant', content: 'olá!' }]

      # Act
      messages = build(history: history).input[0..-2]

      # Assert
      expect(messages.map { |m| text_of(m) }).to eq(['oi', 'olá!'])
    end
  end
end
