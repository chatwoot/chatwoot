# frozen_string_literal: true

def should_support_mysql_import_functionality
  # Forcefully disable strict mode for this session.
  ActiveRecord::Base.connection.execute "set sql_mode='STRICT_ALL_TABLES'"

  should_support_basic_on_duplicate_key_update
  should_support_on_duplicate_key_ignore

  describe "#import" do
    context "with :on_duplicate_key_update and validation checks turned off" do
      extend ActiveSupport::TestCase::ImportAssertions

      asssertion_group(:should_support_on_duplicate_key_update) do
        should_not_update_fields_not_mentioned
        should_update_foreign_keys
        should_not_update_created_at_on_timestamp_columns
        should_update_updated_at_on_timestamp_columns
      end

      macro(:perform_import) { raise "supply your own #perform_import in a context below" }
      macro(:updated_topic) { Topic.find(@topic.id) }

      let(:columns) { %w( id title author_name author_email_address parent_id ) }
      let(:values) { [[99, "Book", "John Doe", "john@doe.com", 17]] }
      let(:updated_values) { [[99, "Book - 2nd Edition", "Author Should Not Change", "johndoe@example.com", 57]] }

      macro(:perform_import) do |*opts|
        Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: update_columns, validate: false)
      end

      setup do
        Topic.import columns, values, validate: false
        @topic = Topic.find 99
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

    context "with :synchronization option" do
      let(:topics) { [] }
      let(:values) { [[topics.first.id, "Jerry Carter", "title1"], [topics.last.id, "Chad Fowler", "title2"]] }
      let(:columns) { %w(id author_name title) }

      setup do
        topics << Topic.create!(title: "LDAP", author_name: "Big Bird", content: "Putting Directories to Work.")
        topics << Topic.create!(title: "Rails Recipes", author_name: "Elmo", content: "A trusted collection of solutions.")
      end

      it "synchronizes passed in ActiveRecord model instances with the data just imported" do
        columns2update = ['author_name']

        expected_count = Topic.count
        Topic.import( columns, values,
          validate: false,
          on_duplicate_key_update: columns2update,
          synchronize: topics )

        assert_equal expected_count, Topic.count, "no new records should have been created!"
        assert_equal "Jerry Carter", topics.first.author_name, "wrong author!"
        assert_equal "Chad Fowler", topics.last.author_name, "wrong author!"
      end
    end

    context "with virtual columns" do
      let(:books) { [Book.new(author_name: "foo", title: "bar")] }

      it "ignores virtual columns and creates record" do
        assert_difference "Book.count", +1 do
          Book.import books
        end
      end
    end
  end
end
