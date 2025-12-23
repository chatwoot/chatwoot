# frozen_string_literal: true

require "spec_helper"

# For Active Record 5.x, the association reflection's cache needs be cleared
# because we're stubbing the related constants.
if ActiveRecord::VERSION::MAJOR == 5
  def clear_searchable_cache
    PgSearch::Document.reflect_on_association(:searchable).clear_association_scope_cache
  end
else
  def clear_searchable_cache
  end
end

# rubocop:disable RSpec/NestedGroups
describe PgSearch do
  describe ".multisearch" do
    with_table "pg_search_documents", &DOCUMENTS_SCHEMA

    describe "delegation to PgSearch::Document.search" do
      subject { described_class.multisearch(query) }

      let(:query) { instance_double("String", "query") }
      let(:relation) { instance_double("ActiveRecord::Relation", "relation") }

      before do
        allow(PgSearch::Document).to receive(:search).with(query).and_return(relation)
      end

      it { is_expected.to eq(relation) }
    end

    context "with PgSearch.multisearch_options set to a Hash" do
      subject do
        clear_searchable_cache
        described_class.multisearch(query).map(&:searchable)
      end

      before { allow(described_class).to receive(:multisearch_options).and_return(using: :dmetaphone) }

      with_model :MultisearchableModel do
        table do |t|
          t.string :title
        end
        model do
          include PgSearch::Model
          multisearchable against: :title
        end
      end

      let!(:soundalike_record) { MultisearchableModel.create!(title: 'foning') }
      let(:query) { "Phoning" }

      it { is_expected.to include(soundalike_record) }
    end

    context "with PgSearch.multisearch_options set to a Proc" do
      subject do
        clear_searchable_cache
        described_class.multisearch(query, soundalike).map(&:searchable)
      end

      before do
        allow(described_class).to receive(:multisearch_options) do
          lambda do |query, soundalike|
            if soundalike
              { using: :dmetaphone, query: query }
            else
              { query: query }
            end
          end
        end
      end

      with_model :MultisearchableModel do
        table do |t|
          t.string :title
        end
        model do
          include PgSearch::Model
          multisearchable against: :title
        end
      end

      let!(:soundalike_record) { MultisearchableModel.create!(title: 'foning') }
      let(:query) { "Phoning" }

      context "with soundalike true" do
        let(:soundalike) { true }

        it { is_expected.to include(soundalike_record) }
      end

      context "with soundalike false" do
        let(:soundalike) { false }

        it { is_expected.not_to include(soundalike_record) }
      end
    end

    context "when on an STI subclass" do
      context "with standard type column" do
        with_model :SuperclassModel do
          table do |t|
            t.text 'content'
            t.string 'type'
          end
        end

        before do
          searchable_subclass_model = Class.new(SuperclassModel) do
            include PgSearch::Model
            multisearchable against: :content
          end
          stub_const("SearchableSubclassModel", searchable_subclass_model)
          stub_const("AnotherSearchableSubclassModel", searchable_subclass_model)
          stub_const("NonSearchableSubclassModel", Class.new(SuperclassModel))
        end

        it "returns only results for that subclass" do
          included = SearchableSubclassModel.create!(content: "foo bar")

          SearchableSubclassModel.create!(content: "baz")
          SuperclassModel.create!(content: "foo bar")
          SuperclassModel.create!(content: "baz")
          NonSearchableSubclassModel.create!(content: "foo bar")
          NonSearchableSubclassModel.create!(content: "baz")

          expect(SuperclassModel.count).to be 6
          expect(SearchableSubclassModel.count).to be 2

          expect(PgSearch::Document.count).to be 2

          results = described_class.multisearch("foo bar")

          expect(results).to eq [included.pg_search_document]
        end

        it "updates an existing STI model does not create a new pg_search document" do
          model = SearchableSubclassModel.create!(content: "foo bar")
          expect(SearchableSubclassModel.count).to eq(1)
          # We fetch the model from the database again otherwise
          # the pg_search_document from the cache is used.
          model = SearchableSubclassModel.find(model.id)
          model.content = "foo"
          model.save!
          results = described_class.multisearch("foo")
          expect(results.size).to eq(SearchableSubclassModel.count)
        end

        # rubocop:disable RSpec/MultipleExpectations
        specify "reindexing works" do
          NonSearchableSubclassModel.create!(content: "foo bar")
          NonSearchableSubclassModel.create!(content: "baz")
          expected = SearchableSubclassModel.create!(content: "baz")
          SuperclassModel.create!(content: "foo bar")
          SuperclassModel.create!(content: "baz")
          SuperclassModel.create!(content: "baz2")

          expect(SuperclassModel.count).to be 6
          expect(NonSearchableSubclassModel.count).to be 2
          expect(SearchableSubclassModel.count).to be 1

          expect(PgSearch::Document.count).to be 1

          PgSearch::Multisearch.rebuild(SearchableSubclassModel)

          clear_searchable_cache
          expect(PgSearch::Document.count).to be 1
          expect(PgSearch::Document.first.searchable.class).to be SearchableSubclassModel
          expect(PgSearch::Document.first.searchable).to eq expected
        end
        # rubocop:enable RSpec/MultipleExpectations

        it "reindexing searchable STI doesn't clobber other related STI models" do
          SearchableSubclassModel.create!(content: "baz")
          AnotherSearchableSubclassModel.create!(content: "baz")

          expect(PgSearch::Document.count).to be 2
          PgSearch::Multisearch.rebuild(SearchableSubclassModel)
          expect(PgSearch::Document.count).to be 2

          clear_searchable_cache
          classes = PgSearch::Document.all.collect { |d| d.searchable.class }
          expect(classes).to include SearchableSubclassModel
          expect(classes).to include AnotherSearchableSubclassModel
        end
      end

      context "with custom type column" do
        with_model :SuperclassModel do
          table do |t|
            t.text 'content'
            t.string 'inherit'
          end

          model do
            self.inheritance_column = 'inherit'
          end
        end

        before do
          searchable_subclass_model = Class.new(SuperclassModel) do
            include PgSearch::Model
            multisearchable against: :content
          end
          stub_const("SearchableSubclassModel", searchable_subclass_model)
          stub_const("AnotherSearchableSubclassModel", searchable_subclass_model)
          stub_const("NonSearchableSubclassModel", Class.new(SuperclassModel))
        end

        it "returns only results for that subclass" do
          included = SearchableSubclassModel.create!(content: "foo bar")

          SearchableSubclassModel.create!(content: "baz")
          SuperclassModel.create!(content: "foo bar")
          SuperclassModel.create!(content: "baz")
          NonSearchableSubclassModel.create!(content: "foo bar")
          NonSearchableSubclassModel.create!(content: "baz")

          expect(SuperclassModel.count).to be 6
          expect(SearchableSubclassModel.count).to be 2

          expect(PgSearch::Document.count).to be 2

          results = described_class.multisearch("foo bar")

          expect(results).to eq [included.pg_search_document]
        end
      end
    end
  end

  describe ".disable_multisearch" do
    it "disables multisearch temporarily" do
      multisearch_enabled_before = described_class.multisearch_enabled?
      multisearch_enabled_inside = nil
      described_class.disable_multisearch do
        multisearch_enabled_inside = described_class.multisearch_enabled?
      end
      multisearch_enabled_after = described_class.multisearch_enabled?

      expect(multisearch_enabled_before).to be(true)
      expect(multisearch_enabled_inside).to be(false)
      expect(multisearch_enabled_after).to be(true)
    end

    it "reenables multisearch after an error" do
      multisearch_enabled_before = described_class.multisearch_enabled?
      multisearch_enabled_inside = nil
      begin
        described_class.disable_multisearch do
          multisearch_enabled_inside = described_class.multisearch_enabled?
          raise
        end
      rescue StandardError
      end
      multisearch_enabled_after = described_class.multisearch_enabled?

      expect(multisearch_enabled_before).to be(true)
      expect(multisearch_enabled_inside).to be(false)
      expect(multisearch_enabled_after).to be(true)
    end

    # rubocop:disable RSpec/ExampleLength
    it "does not disable multisearch on other threads" do
      values = Queue.new
      sync = Queue.new
      Thread.new do
        values.push described_class.multisearch_enabled?
        sync.pop # wait
        values.push described_class.multisearch_enabled?
        sync.pop # wait
        values.push described_class.multisearch_enabled?
      end

      multisearch_enabled_before = values.pop
      multisearch_enabled_inside = nil
      described_class.disable_multisearch do
        sync.push :go
        multisearch_enabled_inside = values.pop
      end
      sync.push :go
      multisearch_enabled_after = values.pop

      expect(multisearch_enabled_before).to be(true)
      expect(multisearch_enabled_inside).to be(true)
      expect(multisearch_enabled_after).to be(true)
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
# rubocop:enable RSpec/NestedGroups
