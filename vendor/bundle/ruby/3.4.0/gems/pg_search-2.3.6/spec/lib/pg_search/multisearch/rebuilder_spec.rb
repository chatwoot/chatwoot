# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/NestedGroups
describe PgSearch::Multisearch::Rebuilder do
  with_table "pg_search_documents", &DOCUMENTS_SCHEMA

  describe 'when initialized with a model that is not multisearchable' do
    with_model :not_multisearchable

    it 'raises an exception' do
      expect {
        described_class.new(NotMultisearchable)
      }.to raise_exception(
        PgSearch::Multisearch::ModelNotMultisearchable,
        "NotMultisearchable is not multisearchable. See PgSearch::ClassMethods#multisearchable"
      )
    end
  end

  describe "#rebuild" do
    context "when the model defines .rebuild_pg_search_documents" do
      context "when multisearchable is not conditional" do
        with_model :Model do
          model do
            include PgSearch::Model
            multisearchable

            def rebuild_pg_search_documents
            end
          end
        end

        it "calls .rebuild_pg_search_documents" do
          rebuilder = described_class.new(Model)

          without_partial_double_verification do
            allow(Model).to receive(:rebuild_pg_search_documents)
            rebuilder.rebuild
            expect(Model).to have_received(:rebuild_pg_search_documents)
          end
        end
      end

      context "when multisearchable is conditional" do
        %i[if unless].each do |conditional_key|
          context "via :#{conditional_key}" do
            with_model :Model do
              table do |t|
                t.boolean :active
              end

              model do
                include PgSearch::Model
                multisearchable conditional_key => :active?

                def rebuild_pg_search_documents
                end
              end
            end

            it "calls .rebuild_pg_search_documents" do
              rebuilder = described_class.new(Model)

              without_partial_double_verification do
                allow(Model).to receive(:rebuild_pg_search_documents)
                rebuilder.rebuild
                expect(Model).to have_received(:rebuild_pg_search_documents)
              end
            end
          end
        end
      end
    end

    context "when the model does not define .rebuild_pg_search_documents" do
      context "when multisearchable is not conditional" do
        context "when :against only includes columns" do
          with_model :Model do
            table do |t|
              t.string :name
            end

            model do
              include PgSearch::Model
              multisearchable against: :name
            end
          end

          it "does not call :rebuild_pg_search_documents" do
            rebuilder = described_class.new(Model)

            # stub respond_to? to return false since should_not_receive defines the method
            original_respond_to = Model.method(:respond_to?)
            allow(Model).to receive(:respond_to?) do |method_name, *args|
              if method_name == :rebuild_pg_search_documents
                false
              else
                original_respond_to.call(method_name, *args)
              end
            end

            without_partial_double_verification do
              allow(Model).to receive(:rebuild_pg_search_documents)
              rebuilder.rebuild
              expect(Model).not_to have_received(:rebuild_pg_search_documents)
            end
          end

          # rubocop:disable RSpec/ExampleLength
          it "executes the default SQL" do
            time = Time.utc(2001, 1, 1, 0, 0, 0)
            rebuilder = described_class.new(Model, -> { time })

            expected_sql = <<~SQL.squish
              INSERT INTO "pg_search_documents" (searchable_type, searchable_id, content, created_at, updated_at)
                SELECT 'Model' AS searchable_type,
                       #{Model.quoted_table_name}.#{Model.primary_key} AS searchable_id,
                       (
                         coalesce(#{Model.quoted_table_name}."name"::text, '')
                       ) AS content,
                       '2001-01-01 00:00:00' AS created_at,
                       '2001-01-01 00:00:00' AS updated_at
                FROM #{Model.quoted_table_name}
            SQL

            executed_sql = []

            notifier = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
              executed_sql << payload[:sql] if payload[:sql].include?(%(INSERT INTO "pg_search_documents"))
            end

            rebuilder.rebuild
            ActiveSupport::Notifications.unsubscribe(notifier)

            expect(executed_sql.length).to eq(1)
            expect(executed_sql.first.strip).to eq(expected_sql.strip)
          end
          # rubocop:enable RSpec/ExampleLength

          context "with a model with a camel case column" do
            with_model :ModelWithCamelCaseColumn do
              table do |t|
                t.string :camelName
              end

              model do
                include PgSearch::Model
                multisearchable against: :name
              end
            end

            it "creates search document without PG error" do
              time = Time.utc(2001, 1, 1, 0, 0, 0)
              rebuilder = described_class.new(Model, -> { time })
              rebuilder.rebuild
            end
          end

          context "with a model with a non-standard primary key" do
            with_model :ModelWithNonStandardPrimaryKey do
              table primary_key: :non_standard_primary_key do |t|
                t.string :name
              end

              model do
                include PgSearch::Model
                multisearchable against: :name
              end
            end

            # rubocop:disable RSpec/ExampleLength
            it "generates SQL with the correct primary key" do
              time = Time.utc(2001, 1, 1, 0, 0, 0)
              rebuilder = described_class.new(ModelWithNonStandardPrimaryKey, -> { time })

              expected_sql = <<~SQL.squish
                INSERT INTO "pg_search_documents" (searchable_type, searchable_id, content, created_at, updated_at)
                  SELECT 'ModelWithNonStandardPrimaryKey' AS searchable_type,
                         #{ModelWithNonStandardPrimaryKey.quoted_table_name}.non_standard_primary_key AS searchable_id,
                         (
                           coalesce(#{ModelWithNonStandardPrimaryKey.quoted_table_name}."name"::text, '')
                         ) AS content,
                         '2001-01-01 00:00:00' AS created_at,
                         '2001-01-01 00:00:00' AS updated_at
                  FROM #{ModelWithNonStandardPrimaryKey.quoted_table_name}
              SQL

              executed_sql = []

              notifier = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
                executed_sql << payload[:sql] if payload[:sql].include?(%(INSERT INTO "pg_search_documents"))
              end

              rebuilder.rebuild
              ActiveSupport::Notifications.unsubscribe(notifier)

              expect(executed_sql.length).to eq(1)
              expect(executed_sql.first.strip).to eq(expected_sql.strip)
            end
            # rubocop:enable RSpec/ExampleLength
          end
        end

        context "when :against includes non-column dynamic methods" do
          with_model :Model do
            model do
              include PgSearch::Model
              multisearchable against: [:foo]

              def foo
                "bar"
              end
            end
          end

          # rubocop:disable RSpec/ExampleLength
          it "calls update_pg_search_document on each record" do
            record = Model.create!

            rebuilder = described_class.new(Model)

            # stub respond_to? to return false since should_not_receive defines the method
            original_respond_to = Model.method(:respond_to?)
            allow(Model).to receive(:respond_to?) do |method_name, *args|
              if method_name == :rebuild_pg_search_documents
                false
              else
                original_respond_to.call(method_name, *args)
              end
            end

            without_partial_double_verification do
              allow(Model).to receive(:rebuild_pg_search_documents)

              rebuilder.rebuild

              expect(Model).not_to have_received(:rebuild_pg_search_documents)
            end

            expect(record.pg_search_document).to be_present
          end
          # rubocop:enable RSpec/ExampleLength
        end

        context "when only additional_attributes is set" do
          with_model :Model do
            table do |t|
              t.string :name
            end

            model do
              include PgSearch::Model
              multisearchable against: :name,
                              additional_attributes: ->(obj) { { additional_attribute_column: "#{obj.class}::#{obj.id}" } }
            end
          end

          it "calls update_pg_search_document on each record" do
            record_1 = Model.create!(name: "record_1", id: 1)
            record_2 = Model.create!(name: "record_2", id: 2)

            PgSearch::Document.delete_all

            rebuilder = described_class.new(Model)
            rebuilder.rebuild

            expect(record_1.reload.pg_search_document.additional_attribute_column).to eq("Model::1")
            expect(record_2.reload.pg_search_document.additional_attribute_column).to eq("Model::2")
          end
        end
      end

      context "when multisearchable is conditional" do
        context "via :if" do
          with_model :Model do
            table do |t|
              t.boolean :active
            end

            model do
              include PgSearch::Model
              multisearchable if: :active?
            end
          end

          # rubocop:disable RSpec/ExampleLength
          it "calls update_pg_search_document on each record" do
            record_1 = Model.create!(active: true)
            record_2 = Model.create!(active: false)

            rebuilder = described_class.new(Model)

            # stub respond_to? to return false since should_not_receive defines the method
            original_respond_to = Model.method(:respond_to?)
            allow(Model).to receive(:respond_to?) do |method_name, *args|
              if method_name == :rebuild_pg_search_documents
                false
              else
                original_respond_to.call(method_name, *args)
              end
            end

            without_partial_double_verification do
              allow(Model).to receive(:rebuild_pg_search_documents)
              rebuilder.rebuild
              expect(Model).not_to have_received(:rebuild_pg_search_documents)
            end

            expect(record_1.pg_search_document).to be_present
            expect(record_2.pg_search_document).not_to be_present
          end
          # rubocop:enable RSpec/ExampleLength
        end

        context "via :unless" do
          with_model :Model do
            table do |t|
              t.boolean :inactive
            end

            model do
              include PgSearch::Model
              multisearchable unless: :inactive?
            end
          end

          # rubocop:disable RSpec/ExampleLength
          it "calls update_pg_search_document on each record" do
            record_1 = Model.create!(inactive: true)
            record_2 = Model.create!(inactive: false)

            rebuilder = described_class.new(Model)

            # stub respond_to? to return false since should_not_receive defines the method
            original_respond_to = Model.method(:respond_to?)
            allow(Model).to receive(:respond_to?) do |method_name, *args|
              if method_name == :rebuild_pg_search_documents
                false
              else
                original_respond_to.call(method_name, *args)
              end
            end

            without_partial_double_verification do
              allow(Model).to receive(:rebuild_pg_search_documents)
              rebuilder.rebuild
              expect(Model).not_to have_received(:rebuild_pg_search_documents)
            end

            expect(record_1.pg_search_document).not_to be_present
            expect(record_2.pg_search_document).to be_present
          end
          # rubocop:enable RSpec/ExampleLength
        end
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
