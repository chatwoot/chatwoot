# frozen_string_literal: true

def should_support_on_duplicate_key_ignore
  describe "#import" do
    extend ActiveSupport::TestCase::ImportAssertions
    let(:topic) { Topic.create!(title: "Book", author_name: "John Doe") }
    let(:topics) { [topic] }

    context "with :on_duplicate_key_ignore" do
      it "should skip duplicates and continue import" do
        topics << Topic.new(title: "Book 2", author_name: "Jane Doe")
        assert_difference "Topic.count", +1 do
          result = Topic.import topics, on_duplicate_key_ignore: true, validate: false
          assert_not_equal topics.first.id, result.ids.first
          assert_nil topics.last.id
        end
      end

      unless ENV["SKIP_COMPOSITE_PK"]
        context "with composite primary keys" do
          it "should import array of values successfully" do
            columns = [:tag_id, :publisher_id, :tag]
            values = [[1, 1, 'Mystery'], [1, 1, 'Science']]

            assert_difference "Tag.count", +1 do
              Tag.import columns, values, on_duplicate_key_ignore: true, validate: false
            end
            assert_equal 'Mystery', Tag.first.tag
          end
        end
      end
    end

    context "with :ignore" do
      it "should skip duplicates and continue import" do
        topics << Topic.new(title: "Book 2", author_name: "Jane Doe")
        assert_difference "Topic.count", +1 do
          result = Topic.import topics, ignore: true, validate: false
          assert_not_equal topics.first.id, result.ids.first
          assert_nil topics.last.id
        end
      end
    end
  end
end
