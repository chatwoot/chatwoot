# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
describe PgSearch::Features::Trigram do
  subject(:feature) { described_class.new(query, options, columns, Model, normalizer) }

  let(:query) { 'lolwut' }
  let(:options) { {} }
  let(:columns) {
    [
      PgSearch::Configuration::Column.new(:name, nil, Model),
      PgSearch::Configuration::Column.new(:content, nil, Model)
    ]
  }
  let(:normalizer) { PgSearch::Normalizer.new(config) }
  let(:config) { OpenStruct.new(ignore: []) } # rubocop:disable Style/OpenStructUse

  let(:coalesced_columns) do
    <<~SQL.squish
      coalesce(#{Model.quoted_table_name}."name"::text, '')
        || ' '
        || coalesce(#{Model.quoted_table_name}."content"::text, '')
    SQL
  end

  with_model :Model do
    table do |t|
      t.string :name
      t.string :content
    end
  end

  describe 'conditions' do
    it 'escapes the search document and query' do
      config.ignore = []
      expect(feature.conditions.to_sql).to eq("('#{query}' % (#{coalesced_columns}))")
    end

    context 'when searching by word_similarity' do
      let(:options) do
        { word_similarity: true }
      end

      it 'uses the "<%" operator when searching by word_similarity' do
        config.ignore = []
        expect(feature.conditions.to_sql).to eq("('#{query}' <% (#{coalesced_columns}))")
      end
    end

    context 'when ignoring accents' do
      it 'escapes the search document and query, but not the accent function' do
        config.ignore = [:accents]
        expect(feature.conditions.to_sql).to eq("(unaccent('#{query}') % (unaccent(#{coalesced_columns})))")
      end
    end

    context 'when a threshold is specified' do
      context 'when searching by similarity' do
        let(:options) do
          { threshold: 0.5 }
        end

        it 'uses a minimum similarity expression instead of the "%" operator' do
          expect(feature.conditions.to_sql).to eq(
            "(similarity('#{query}', (#{coalesced_columns})) >= 0.5)"
          )
        end
      end

      context 'when searching by word_similarity' do
        let(:options) do
          { threshold: 0.5, word_similarity: true }
        end

        it 'uses a minimum similarity expression instead of the "<%" operator' do
          expect(feature.conditions.to_sql).to eq(
            "(word_similarity('#{query}', (#{coalesced_columns})) >= 0.5)"
          )
        end
      end
    end

    context 'when only certain columns are selected' do
      context 'with one column' do
        let(:options) { { only: :name } }

        it 'only searches against the select column' do
          coalesced_column = "coalesce(#{Model.quoted_table_name}.\"name\"::text, '')"
          expect(feature.conditions.to_sql).to eq("('#{query}' % (#{coalesced_column}))")
        end
      end

      context 'with multiple columns' do
        let(:options) { { only: %i[name content] } }

        it 'concatenates when multiples columns are selected' do
          expect(feature.conditions.to_sql).to eq("('#{query}' % (#{coalesced_columns}))")
        end
      end
    end
  end

  describe '#rank' do
    it 'returns an expression using the similarity() function' do
      expect(feature.rank.to_sql).to eq("(similarity('#{query}', (#{coalesced_columns})))")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
