module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_one_attached` matcher tests usage of the
      # `has_one_attached` macro.
      #
      # #### Example
      #
      #     class User < ApplicationRecord
      #       has_one_attached :avatar
      #     end
      #
      #     # RSpec
      #     RSpec.describe User, type: :model do
      #       it { should have_one_attached(:avatar) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UserTest < ActiveSupport::TestCase
      #       should have_one_attached(:avatar)
      #     end
      #
      # @return [HaveAttachedMatcher]
      #
      def have_one_attached(name)
        HaveAttachedMatcher.new(:one, name)
      end

      # The `have_many_attached` matcher tests usage of the
      # `has_many_attached` macro.
      #
      # #### Example
      #
      #     class Message < ApplicationRecord
      #       has_many_attached :images
      #     end
      #
      #     # RSpec
      #     RSpec.describe Message, type: :model do
      #       it { should have_many_attached(:images) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class MessageTest < ActiveSupport::TestCase
      #       should have_many_attached(:images)
      #     end
      #
      # @return [HaveAttachedMatcher]
      #
      def have_many_attached(name)
        HaveAttachedMatcher.new(:many, name)
      end

      # @private
      class HaveAttachedMatcher
        attr_reader :name

        def initialize(macro, name)
          @macro = macro
          @name = name
        end

        def description
          "have a has_#{macro}_attached called #{name}"
        end

        def failure_message
          <<-MESSAGE
Expected #{expectation}, but this could not be proved.
  #{@failure}
          MESSAGE
        end

        def failure_message_when_negated
          <<-MESSAGE
Did not expect #{expectation}, but it does.
          MESSAGE
        end

        def expectation
          "#{model_class.name} to #{description}"
        end

        def matches?(subject)
          @subject = subject
          reader_attribute_exists? &&
            writer_attribute_exists? &&
            attachments_association_exists? &&
            blobs_association_exists? &&
            eager_loading_scope_exists?
        end

        private

        attr_reader :subject, :macro

        def reader_attribute_exists?
          if subject.respond_to?(name)
            true
          else
            @failure = "#{model_class.name} does not have a :#{name} method."
            false
          end
        end

        def writer_attribute_exists?
          if subject.respond_to?("#{name}=")
            true
          else
            @failure = "#{model_class.name} does not have a :#{name}= method."
            false
          end
        end

        def attachments_association_exists?
          if attachments_association_matcher.matches?(subject)
            true
          else
            @failure = attachments_association_matcher.failure_message
            false
          end
        end

        def attachments_association_matcher
          @_attachments_association_matcher ||=
            AssociationMatcher.new(
              :"has_#{macro}",
              attachments_association_name,
            ).
              conditions(name: name).
              class_name('ActiveStorage::Attachment').
              inverse_of(:record)
        end

        def attachments_association_name
          case macro
          when :one then "#{name}_attachment"
          when :many then "#{name}_attachments"
          end
        end

        def blobs_association_exists?
          if blobs_association_matcher.matches?(subject)
            true
          else
            @failure = blobs_association_matcher.failure_message
            false
          end
        end

        def blobs_association_matcher
          @_blobs_association_matcher ||=
            AssociationMatcher.new(
              :"has_#{macro}",
              blobs_association_name,
            ).
              through(attachments_association_name).
              class_name('ActiveStorage::Blob').
              source(:blob)
        end

        def blobs_association_name
          case macro
          when :one then "#{name}_blob"
          when :many then "#{name}_blobs"
          end
        end

        def eager_loading_scope_exists?
          if model_class.respond_to?("with_attached_#{name}")
            true
          else
            @failure = "#{model_class.name} does not have a " \
                       ":with_attached_#{name} scope."
            false
          end
        end

        def model_class
          subject.class
        end
      end
    end
  end
end
