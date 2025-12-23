module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_rich_text` matcher tests usage of the
      # `has_rich_text` macro.
      #
      # #### Example
      #
      #     class Post < ActiveRecord
      #       has_rich_text :content
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should have_rich_text(:content) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should have_rich_text(:content)
      #     end
      #
      # @return [HaveRichTextMatcher]
      #
      def have_rich_text(rich_text_attribute)
        HaveRichTextMatcher.new(rich_text_attribute)
      end

      # @private
      class HaveRichTextMatcher
        def initialize(rich_text_attribute)
          @rich_text_attribute = rich_text_attribute
        end

        def description
          "have configured :#{rich_text_attribute} as a "\
          'ActionText::RichText association'
        end

        def failure_message
          "Expected #{subject.class} to #{error_description}"
        end

        def failure_message_when_negated
          "Did not expect #{subject.class} to have ActionText::RichText"\
          " :#{rich_text_attribute}"
        end

        def matches?(subject)
          @subject = subject
          @error = run_checks
          @error.nil?
        end

        private

        attr_reader :error, :rich_text_attribute, :subject

        def run_checks
          if !has_attribute?
            ":#{rich_text_attribute} does not exist"
          elsif !has_expected_action_text?
            :default
          end
        end

        def has_attribute?
          @subject.respond_to?(rich_text_attribute.to_s)
        end

        def has_expected_action_text?
          defined?(ActionText::RichText) &&
            @subject.send(rich_text_attribute).
              instance_of?(ActionText::RichText)
        end

        def error_description
          error == :default ? description : "#{description} but #{error}"
        end
      end
    end
  end
end
