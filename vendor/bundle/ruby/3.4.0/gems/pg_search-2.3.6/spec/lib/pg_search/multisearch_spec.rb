# frozen_string_literal: true

require "spec_helper"
require "active_support/deprecation"

# rubocop:disable RSpec/NestedGroups
describe PgSearch::Multisearch do
  with_table "pg_search_documents", &DOCUMENTS_SCHEMA

  with_model :MultisearchableModel do
    table do |t|
      t.string :title
      t.text :content
      t.timestamps null: false
    end
    model do
      include PgSearch::Model
    end
  end

  let(:model) { MultisearchableModel }
  let(:connection) { model.connection }

  describe ".rebuild" do
    before do
      model.multisearchable against: :title
    end

    it "operates inside a transaction" do
      allow(model).to receive(:transaction)

      described_class.rebuild(model)
      expect(model).to have_received(:transaction).once
    end

    context "when transactional is false" do
      it "does not operate inside a transaction" do
        allow(model).to receive(:transaction)

        described_class.rebuild(model, transactional: false)
        expect(model).not_to have_received(:transaction)
      end
    end

    describe "cleaning up search documents for this model" do
      before do
        connection.execute <<~SQL.squish
          INSERT INTO pg_search_documents
            (searchable_type, searchable_id, content, created_at, updated_at)
            VALUES
            ('#{model.name}', 123, 'foo', now(), now());
          INSERT INTO pg_search_documents
            (searchable_type, searchable_id, content, created_at, updated_at)
            VALUES
            ('Bar', 123, 'foo', now(), now());
        SQL
        expect(PgSearch::Document.count).to eq(2)
      end

      context "when clean_up is not passed" do
        it "deletes the document for the model" do
          described_class.rebuild(model)
          expect(PgSearch::Document.count).to eq(1)
          expect(PgSearch::Document.first.searchable_type).to eq("Bar")
        end
      end

      context "when clean_up is true" do
        it "deletes the document for the model" do
          described_class.rebuild(model, clean_up: true)
          expect(PgSearch::Document.count).to eq(1)
          expect(PgSearch::Document.first.searchable_type).to eq("Bar")
        end
      end

      context "when clean_up is false" do
        it "does not delete the document for the model" do
          described_class.rebuild(model, clean_up: false)
          expect(PgSearch::Document.count).to eq(2)
        end
      end

      context "when deprecated_clean_up is true" do
        it "deletes the document for the model" do
          ActiveSupport::Deprecation.silence { described_class.rebuild(model, true) }
          expect(PgSearch::Document.count).to eq(1)
          expect(PgSearch::Document.first.searchable_type).to eq("Bar")
        end
      end

      context "when deprecated_clean_up is false" do
        it "does not delete the document for the model" do
          ActiveSupport::Deprecation.silence { described_class.rebuild(model, false) }
          expect(PgSearch::Document.count).to eq(2)
        end
      end

      context "when the model implements .rebuild_pg_search_documents" do
        before do
          def model.rebuild_pg_search_documents
            connection.execute <<~SQL.squish
              INSERT INTO pg_search_documents
                (searchable_type, searchable_id, content, created_at, updated_at)
                VALUES
                ('Baz', 789, 'baz', now(), now());
            SQL
          end
        end

        it "calls .rebuild_pg_search_documents and skips the default behavior" do
          without_partial_double_verification do
            allow(model).to receive(:rebuild_sql)
            described_class.rebuild(model)

            record = PgSearch::Document.find_by(searchable_type: "Baz", searchable_id: 789)
            expect(model).not_to have_received(:rebuild_sql)
            expect(record.content).to eq("baz")
          end
        end
      end
    end

    describe "inserting the new documents" do
      let!(:new_models) { [] }

      before do
        new_models << model.create!(title: "Foo", content: "Bar")
        new_models << model.create!(title: "Baz", content: "Bar")
      end

      it "creates new documents for the two models" do
        described_class.rebuild(model)
        expect(PgSearch::Document.last(2).map(&:searchable).map(&:title)).to match_array(new_models.map(&:title))
      end
    end

    describe "the generated SQL" do
      let(:now) { Time.now }

      before { allow(Time).to receive(:now).and_return(now) }

      context "with one attribute" do
        before do
          model.multisearchable against: [:title]
        end

        it "generates the proper SQL code" do
          expected_sql = <<~SQL.squish
            INSERT INTO #{PgSearch::Document.quoted_table_name} (searchable_type, searchable_id, content, created_at, updated_at)
              SELECT #{connection.quote(model.name)} AS searchable_type,
                     #{model.quoted_table_name}.id AS searchable_id,
                     (
                       coalesce(#{model.quoted_table_name}."title"::text, '')
                     ) AS content,
                     #{connection.quote(connection.quoted_date(now))} AS created_at,
                     #{connection.quote(connection.quoted_date(now))} AS updated_at
              FROM #{model.quoted_table_name}
          SQL

          statements = []
          allow(connection).to receive(:execute) { |sql| statements << sql.strip }

          described_class.rebuild(model)

          expect(statements).to include(expected_sql.strip)
        end
      end

      context "with multiple attributes" do
        before do
          model.multisearchable against: %i[title content]
        end

        it "generates the proper SQL code" do
          expected_sql = <<~SQL.squish
            INSERT INTO #{PgSearch::Document.quoted_table_name} (searchable_type, searchable_id, content, created_at, updated_at)
              SELECT #{connection.quote(model.name)} AS searchable_type,
                     #{model.quoted_table_name}.id AS searchable_id,
                     (
                       coalesce(#{model.quoted_table_name}."title"::text, '') || ' ' || coalesce(#{model.quoted_table_name}."content"::text, '')
                     ) AS content,
                     #{connection.quote(connection.quoted_date(now))} AS created_at,
                     #{connection.quote(connection.quoted_date(now))} AS updated_at
              FROM #{model.quoted_table_name}
          SQL

          statements = []
          allow(connection).to receive(:execute) { |sql| statements << sql.strip }

          described_class.rebuild(model)

          expect(statements).to include(expected_sql.strip)
        end
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
