# frozen_string_literal: true

def should_support_sqlite3_import_functionality
  if ActiveRecord::Base.connection.supports_on_duplicate_key_update?
    should_support_sqlite_upsert_functionality
  end

  describe "#supports_imports?" do
    it "should support import" do
      assert ActiveRecord::Base.supports_import?
    end
  end

  describe "#import" do
    it "imports with a single insert on SQLite 3.7.11 or higher" do
      assert_difference "Topic.count", +507 do
        result = Topic.import Build(7, :topics)
        assert_equal 1, result.num_inserts, "Failed to issue a single INSERT statement. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
        assert_equal 7, Topic.count, "Failed to insert all records. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"

        result = Topic.import Build(500, :topics)
        assert_equal 1, result.num_inserts, "Failed to issue a single INSERT statement. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
        assert_equal 507, Topic.count, "Failed to insert all records. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
      end
    end

    it "imports with a two inserts on SQLite 3.7.11 or higher" do
      assert_difference "Topic.count", +501 do
        result = Topic.import Build(501, :topics)
        assert_equal 2, result.num_inserts, "Failed to issue a two INSERT statements. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
        assert_equal 501, Topic.count, "Failed to insert all records. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
      end
    end

    it "imports with a five inserts on SQLite 3.7.11 or higher" do
      assert_difference "Topic.count", +2500 do
        result = Topic.import Build(2500, :topics)
        assert_equal 5, result.num_inserts, "Failed to issue a two INSERT statements. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
        assert_equal 2500, Topic.count, "Failed to insert all records. Make sure you have a supported version of SQLite3 (3.7.11 or higher) installed"
      end
    end
  end
end

def should_support_sqlite_upsert_functionality
  should_support_basic_on_duplicate_key_update
  should_support_on_duplicate_key_ignore

  describe "#import" do
    extend ActiveSupport::TestCase::ImportAssertions

    macro(:perform_import) { raise "supply your own #perform_import in a context below" }
    macro(:updated_topic) { Topic.find(@topic.id) }

    context "with :on_duplicate_key_ignore and validation checks turned off" do
      let(:columns) { %w( id title author_name author_email_address parent_id ) }
      let(:values) { [[99, "Book", "John Doe", "john@doe.com", 17]] }
      let(:updated_values) { [[99, "Book - 2nd Edition", "Author Should Not Change", "johndoe@example.com", 57]] }

      setup do
        Topic.import columns, values, validate: false
      end

      it "should not update any records" do
        result = Topic.import columns, updated_values, on_duplicate_key_ignore: true, validate: false
        assert_equal [], result.ids
      end
    end

    context "with :on_duplicate_key_update and validation checks turned off" do
      asssertion_group(:should_support_on_duplicate_key_update) do
        should_not_update_fields_not_mentioned
        should_update_foreign_keys
        should_not_update_created_at_on_timestamp_columns
        should_update_updated_at_on_timestamp_columns
      end

      context "using a hash" do
        context "with :columns a hash" do
          let(:columns) { %w( id title author_name author_email_address parent_id ) }
          let(:values) { [[99, "Book", "John Doe", "john@doe.com", 17]] }
          let(:updated_values) { [[99, "Book - 2nd Edition", "Author Should Not Change", "johndoe@example.com", 57]] }

          macro(:perform_import) do |*opts|
            Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: { conflict_target: :id, columns: update_columns }, validate: false)
          end

          setup do
            Topic.import columns, values, validate: false
            @topic = Topic.find 99
          end

          it "should not modify the passed in :on_duplicate_key_update columns array" do
            assert_nothing_raised do
              columns = %w(title author_name).freeze
              Topic.import columns, [%w(foo, bar)], on_duplicate_key_update: { columns: columns }
            end
          end

          context "using string hash map" do
            let(:update_columns) { { "title" => "title", "author_email_address" => "author_email_address", "parent_id" => "parent_id" } }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned
          end

          context "using string hash map, but specifying column mismatches" do
            let(:update_columns) { { "title" => "author_email_address", "author_email_address" => "title", "parent_id" => "parent_id" } }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned_with_hash_mappings
          end

          context "using symbol hash map" do
            let(:update_columns) { { title: :title, author_email_address: :author_email_address, parent_id: :parent_id } }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned
          end

          context "using symbol hash map, but specifying column mismatches" do
            let(:update_columns) { { title: :author_email_address, author_email_address: :title, parent_id: :parent_id } }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned_with_hash_mappings
          end
        end

        context 'with :index_predicate' do
          let(:columns) { %w( id device_id alarm_type status metadata ) }
          let(:values) { [[99, 17, 1, 1, 'foo']] }
          let(:updated_values) { [[99, 17, 1, 2, 'bar']] }

          macro(:perform_import) do |*opts|
            Alarm.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: { conflict_target: [:device_id, :alarm_type], index_predicate: 'status <> 0', columns: [:status] }, validate: false)
          end

          macro(:updated_alarm) { Alarm.find(@alarm.id) }

          setup do
            Alarm.import columns, values, validate: false
            @alarm = Alarm.find 99
          end

          context 'supports on duplicate key update for partial indexes' do
            it 'should not update created_at timestamp columns' do
              Timecop.freeze Chronic.parse("5 minutes from now") do
                perform_import
                assert_in_delta @alarm.created_at.to_i, updated_alarm.created_at.to_i, 1
              end
            end

            it 'should update updated_at timestamp columns' do
              time = Chronic.parse("5 minutes from now")
              Timecop.freeze time do
                perform_import
                assert_in_delta time.to_i, updated_alarm.updated_at.to_i, 1
              end
            end

            it 'should not update fields not mentioned' do
              perform_import
              assert_equal 'foo', updated_alarm.metadata
            end

            it 'should update fields mentioned with hash mappings' do
              perform_import
              assert_equal 2, updated_alarm.status
            end
          end
        end

        context 'with :condition' do
          let(:columns) { %w( id device_id alarm_type status metadata) }
          let(:values) { [[99, 17, 1, 1, 'foo']] }
          let(:updated_values) { [[99, 17, 1, 1, 'bar']] }

          macro(:perform_import) do |*opts|
            Alarm.import(
              columns,
              updated_values,
              opts.extract_options!.merge(
                on_duplicate_key_update: {
                  conflict_target: [:id],
                  condition: "alarms.metadata NOT LIKE '%foo%'",
                  columns: [:metadata]
                },
                validate: false
              )
            )
          end

          macro(:updated_alarm) { Alarm.find(@alarm.id) }

          setup do
            Alarm.import columns, values, validate: false
            @alarm = Alarm.find 99
          end

          it 'should not update fields not matched' do
            perform_import
            assert_equal 'foo', updated_alarm.metadata
          end
        end

        context "with no :conflict_target" do
          context "with no primary key" do
            it "raises ArgumentError" do
              error = assert_raises ArgumentError do
                Rule.import Build(3, :rules), on_duplicate_key_update: [:condition_text], validate: false
              end
              assert_match(/Expected :conflict_target to be specified/, error.message)
            end
          end
        end

        context "with no :columns" do
          let(:columns) { %w( id title author_name author_email_address ) }
          let(:values) { [[100, "Book", "John Doe", "john@doe.com"]] }
          let(:updated_values) { [[100, "Title Should Not Change", "Author Should Not Change", "john@nogo.com"]] }

          macro(:perform_import) do |*opts|
            Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: { conflict_target: :id }, validate: false)
          end

          setup do
            Topic.import columns, values, validate: false
            @topic = Topic.find 100
          end

          should_update_updated_at_on_timestamp_columns
        end
      end
    end
  end
end
