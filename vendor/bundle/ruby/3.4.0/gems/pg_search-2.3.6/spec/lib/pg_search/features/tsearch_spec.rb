# frozen_string_literal: true

require "spec_helper"
require "active_support/deprecation"

describe PgSearch::Features::TSearch do
  describe "#rank" do
    with_model :Model do
      table do |t|
        t.string :name
        t.text :content
      end
    end

    it "returns an expression using the ts_rank() function" do
      query = "query"
      columns = [
        PgSearch::Configuration::Column.new(:name, nil, Model),
        PgSearch::Configuration::Column.new(:content, nil, Model)
      ]
      options = {}
      config = instance_double("PgSearch::Configuration", :config, ignore: [])
      normalizer = PgSearch::Normalizer.new(config)

      feature = described_class.new(query, options, columns, Model, normalizer)
      expect(feature.rank.to_sql).to eq(
        %{(ts_rank((to_tsvector('simple', coalesce(#{Model.quoted_table_name}."name"::text, '')) || to_tsvector('simple', coalesce(#{Model.quoted_table_name}."content"::text, ''))), (to_tsquery('simple', ''' ' || 'query' || ' ''')), 0))}
      )
    end
  end

  describe "#conditions" do
    with_model :Model do
      table do |t|
        t.string :name
        t.text :content
      end
    end

    it "returns an expression using the @@ infix operator" do
      query = "query"
      columns = [
        PgSearch::Configuration::Column.new(:name, nil, Model),
        PgSearch::Configuration::Column.new(:content, nil, Model)
      ]
      options = {}
      config = instance_double("PgSearch::Configuration", :config, ignore: [])
      normalizer = PgSearch::Normalizer.new(config)

      feature = described_class.new(query, options, columns, Model, normalizer)
      expect(feature.conditions.to_sql).to eq(
        %{((to_tsvector('simple', coalesce(#{Model.quoted_table_name}."name"::text, '')) || to_tsvector('simple', coalesce(#{Model.quoted_table_name}."content"::text, ''))) @@ (to_tsquery('simple', ''' ' || 'query' || ' ''')))}
      )
    end

    context "when options[:negation] is true" do
      it "returns a negated expression when a query is prepended with !" do
        query = "!query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model),
          PgSearch::Configuration::Column.new(:content, nil, Model)
        ]
        options = { negation: true }
        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)
        expect(feature.conditions.to_sql).to eq(
          %{((to_tsvector('simple', coalesce(#{Model.quoted_table_name}."name"::text, '')) || to_tsvector('simple', coalesce(#{Model.quoted_table_name}."content"::text, ''))) @@ (to_tsquery('simple', '!' || ''' ' || 'query' || ' ''')))}
        )
      end
    end

    context "when options[:negation] is false" do
      it "does not return a negated expression when a query is prepended with !" do
        query = "!query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model),
          PgSearch::Configuration::Column.new(:content, nil, Model)
        ]
        options = { negation: false }
        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)
        expect(feature.conditions.to_sql).to eq(
          %{((to_tsvector('simple', coalesce(#{Model.quoted_table_name}."name"::text, '')) || to_tsvector('simple', coalesce(#{Model.quoted_table_name}."content"::text, ''))) @@ (to_tsquery('simple', ''' ' || '!query' || ' ''')))}
        )
      end
    end

    context "when options[:tsvector_column] is a string" do
      it 'uses the tsvector column' do
        query = "query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model),
          PgSearch::Configuration::Column.new(:content, nil, Model)
        ]
        options = { tsvector_column: "my_tsvector" }
        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)
        expect(feature.conditions.to_sql).to eq(
          %{((#{Model.quoted_table_name}.\"my_tsvector\") @@ (to_tsquery('simple', ''' ' || 'query' || ' ''')))}
        )
      end
    end

    context "when options[:tsvector_column] is an array of strings" do
      it 'uses the tsvector column' do
        query = "query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model),
          PgSearch::Configuration::Column.new(:content, nil, Model)
        ]
        options = { tsvector_column: ["tsvector1", "tsvector2"] }
        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)
        expect(feature.conditions.to_sql).to eq(
          %{((#{Model.quoted_table_name}.\"tsvector1\" || #{Model.quoted_table_name}.\"tsvector2\") @@ (to_tsquery('simple', ''' ' || 'query' || ' ''')))}
        )
      end
    end
  end

  describe "#highlight" do
    with_model :Model do
      table do |t|
        t.string :name
        t.text :content
      end
    end

    it "generates SQL to call ts_headline" do
      query = "query"
      columns = [
        PgSearch::Configuration::Column.new(:name, nil, Model)
      ]
      options = {}

      config = instance_double("PgSearch::Configuration", :config, ignore: [])
      normalizer = PgSearch::Normalizer.new(config)

      feature = described_class.new(query, options, columns, Model, normalizer)
      expect(feature.highlight.to_sql).to eq(
        "(ts_headline('simple', (coalesce(#{Model.quoted_table_name}.\"name\"::text, '')), (to_tsquery('simple', ''' ' || 'query' || ' ''')), ''))"
      )
    end

    context "when options[:dictionary] is passed" do
      # rubocop:disable RSpec/ExampleLength
      it 'uses the provided dictionary' do
        query = "query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model),
          PgSearch::Configuration::Column.new(:content, nil, Model)
        ]
        options = {
          dictionary: "spanish",
          highlight: {
            StartSel: "<b>",
            StopSel: "</b>"
          }
        }

        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)

        expected_sql = %{(ts_headline('spanish', (coalesce(#{Model.quoted_table_name}."name"::text, '') || ' ' || coalesce(#{Model.quoted_table_name}."content"::text, '')), (to_tsquery('spanish', ''' ' || 'query' || ' ''')), 'StartSel = "<b>", StopSel = "</b>"'))}

        expect(feature.highlight.to_sql).to eq(expected_sql)
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context "when options[:highlight] has options set" do
      # rubocop:disable RSpec/ExampleLength
      it "passes the options to ts_headline" do
        query = "query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model)
        ]
        options = {
          highlight: {
            StartSel: '<start class="search">',
            StopSel: '<stop>',
            MaxWords: 123,
            MinWords: 456,
            ShortWord: 4,
            HighlightAll: true,
            MaxFragments: 3,
            FragmentDelimiter: '&hellip;'
          }
        }

        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)

        expected_sql = %{(ts_headline('simple', (coalesce(#{Model.quoted_table_name}."name"::text, '')), (to_tsquery('simple', ''' ' || 'query' || ' ''')), 'StartSel = "<start class=""search"">", StopSel = "<stop>", MaxFragments = 3, MaxWords = 123, MinWords = 456, ShortWord = 4, FragmentDelimiter = "&hellip;", HighlightAll = TRUE'))}

        expect(feature.highlight.to_sql).to eq(expected_sql)
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/ExampleLength
      it "passes deprecated options to ts_headline" do
        query = "query"
        columns = [
          PgSearch::Configuration::Column.new(:name, nil, Model)
        ]
        options = {
          highlight: {
            start_sel: '<start class="search">',
            stop_sel: '<stop>',
            max_words: 123,
            min_words: 456,
            short_word: 4,
            highlight_all: false,
            max_fragments: 3,
            fragment_delimiter: '&hellip;'
          }
        }

        config = instance_double("PgSearch::Configuration", :config, ignore: [])
        normalizer = PgSearch::Normalizer.new(config)

        feature = described_class.new(query, options, columns, Model, normalizer)

        highlight_sql = ActiveSupport::Deprecation.silence { feature.highlight.to_sql }
        expected_sql = %{(ts_headline('simple', (coalesce(#{Model.quoted_table_name}."name"::text, '')), (to_tsquery('simple', ''' ' || 'query' || ' ''')), 'StartSel = "<start class=""search"">", StopSel = "<stop>", MaxFragments = 3, MaxWords = 123, MinWords = 456, ShortWord = 4, FragmentDelimiter = "&hellip;", HighlightAll = FALSE'))}

        expect(highlight_sql).to eq(expected_sql)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
