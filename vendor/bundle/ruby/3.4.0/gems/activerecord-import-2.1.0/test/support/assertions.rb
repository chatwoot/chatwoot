# frozen_string_literal: true

class ActiveSupport::TestCase
  module ImportAssertions
    def self.extended(klass)
      klass.instance_eval do
        assertion(:should_not_update_created_at_on_timestamp_columns) do
          Timecop.freeze Chronic.parse("5 minutes from now") do
            perform_import
            assert_in_delta @topic.created_at.to_i, updated_topic.created_at.to_i, 1
            assert_in_delta @topic.created_on.to_i, updated_topic.created_on.to_i, 1
          end
        end

        assertion(:should_update_updated_at_on_timestamp_columns) do
          time = Chronic.parse("5 minutes from now")
          Timecop.freeze time do
            perform_import
            assert_in_delta time.to_i, updated_topic.updated_at.to_i, 1
            assert_in_delta time.to_i, updated_topic.updated_on.to_i, 1
          end
        end

        assertion(:should_not_update_updated_at_on_timestamp_columns) do
          time = Chronic.parse("5 minutes from now")
          Timecop.freeze time do
            perform_import
            assert_in_delta @topic.updated_at.to_i, updated_topic.updated_at.to_i, 1
            assert_in_delta @topic.updated_on.to_i, updated_topic.updated_on.to_i, 1
          end
        end

        assertion(:should_not_update_timestamps) do
          Timecop.freeze Chronic.parse("5 minutes from now") do
            perform_import timestamps: false
            assert_in_delta @topic.created_at.to_i, updated_topic.created_at.to_i, 1
            assert_in_delta @topic.created_on.to_i, updated_topic.created_on.to_i, 1
            assert_in_delta @topic.updated_at.to_i, updated_topic.updated_at.to_i, 1
            assert_in_delta @topic.updated_on.to_i, updated_topic.updated_on.to_i, 1
          end
        end

        assertion(:should_not_update_fields_not_mentioned) do
          assert_equal "John Doe", updated_topic.author_name
        end

        assertion(:should_update_fields_mentioned) do
          perform_import
          assert_equal "Book - 2nd Edition", updated_topic.title
          assert_equal "johndoe@example.com", updated_topic.author_email_address
        end

        assertion(:should_raise_update_fields_mentioned) do
          assert_raise ActiveRecord::RecordNotUnique do
            perform_import
          end

          assert_equal "Book", updated_topic.title
          assert_equal "john@doe.com", updated_topic.author_email_address
        end

        assertion(:should_update_fields_mentioned_with_hash_mappings) do
          perform_import
          assert_equal "johndoe@example.com", updated_topic.title
          assert_equal "Book - 2nd Edition", updated_topic.author_email_address
        end

        assertion(:should_update_foreign_keys) do
          perform_import
          assert_equal 57, updated_topic.parent_id
        end
      end
    end
  end
end
