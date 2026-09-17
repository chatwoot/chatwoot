# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Apropos::Prompt do
  describe '.parts' do
    subject(:parts) { described_class.parts(:coordinator) }

    it 'keeps the coordinator inside the Chatwoot domain' do
      expect(parts.fetch('foundation')).to include(
        'Chatwoot is its complete working domain',
        'Decline unrelated requests without calling tools',
        'External systems are outside the current domain'
      )
      expect(parts.fetch('coordinator')).to include(
        "Start from the user's Chatwoot objective and domain meaning",
        'Scheme is the execution language, not your identity'
      )
    end

    it 'supplies a broad Chatwoot data model without promising capabilities' do
      data_model = parts.fetch('data_model')

      expect(data_model).to include(
        'inboxes, contacts, conversations, messages, human agents',
        'A concept existing in Chatwoot does not prove',
        'Custom attributes are account-defined JSON'
      )
      expect(data_model).not_to include('slow loading', 'Suggesting labels')
    end

    it 'separates deterministic work from semantic reasoning' do
      expect(parts.fetch('reasoning')).to include(
        'Use deterministic operations for exact conditions, counting, sorting, pagination, and grouping',
        'Use reason when the request requires interpreting meaning',
        'Keyword matching may reduce a candidate set. It does not prove a subjective condition.'
      )
    end

    it 'requires a complete task plan and reports missing data' do
      expect(parts.fetch('planning')).to include(
        'Before the first execute call, identify the objective',
        'Assign every user condition to retrieval, deterministic computation, or reasoning',
        'Do not assume a user concept must correspond to one stored field',
        'map the evidence source',
        'Do not declare data unavailable from a sample',
        'Do not guess field names'
      )
      expect(parts.fetch('coverage')).to include('Track target-record coverage and supporting-evidence coverage separately')
      expect(parts.fetch('retrieval')).to include('Exhaust each independently', 'An ordered first page across many parent records')
      expect(parts.fetch('workspace')).to include('There is no store primitive')
    end

    it 'keeps semantic analysis open to multiple evidence sources' do
      expect(parts.fetch('reasoning')).to include(
        'combine explicit structured facts with relevant narrative evidence',
        'Do not require a canonical database marker or invent a proxy criterion'
      )
      expect(parts.fetch('recovery')).to include(
        'For a write, never act when eligibility cannot be verified',
        'genuinely inconclusive records as unknown'
      )
      expect(parts.fetch('data_model')).to include('Inspect the actual keys and values present in the target data')
    end
  end
end
