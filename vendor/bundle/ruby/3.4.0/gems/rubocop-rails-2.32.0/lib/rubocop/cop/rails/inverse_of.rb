# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for has_(one|many) and belongs_to associations where
      # Active Record can't automatically determine the inverse association
      # because of a scope or the options used. Using the blog with order scope
      # example below, traversing the a Blog's association in both directions
      # with `blog.posts.first.blog` would cause the `blog` to be loaded from
      # the database twice.
      #
      # `:inverse_of` must be manually specified for Active Record to use the
      # associated object in memory, or set to `false` to opt-out. Note that
      # setting `nil` does not stop Active Record from trying to determine the
      # inverse automatically, and is not considered a valid value for this.
      #
      # @example
      #   # good
      #   class Blog < ApplicationRecord
      #     has_many :posts
      #   end
      #
      #   class Post < ApplicationRecord
      #     belongs_to :blog
      #   end
      #
      # @example
      #   # bad
      #   class Blog < ApplicationRecord
      #     has_many :posts, -> { order(published_at: :desc) }
      #   end
      #
      #   class Post < ApplicationRecord
      #     belongs_to :blog
      #   end
      #
      #   # good
      #   class Blog < ApplicationRecord
      #     has_many(:posts,
      #              -> { order(published_at: :desc) },
      #              inverse_of: :blog)
      #   end
      #
      #   class Post < ApplicationRecord
      #     belongs_to :blog
      #   end
      #
      #   # good
      #   class Blog < ApplicationRecord
      #     with_options inverse_of: :blog do
      #       has_many :posts, -> { order(published_at: :desc) }
      #     end
      #   end
      #
      #   class Post < ApplicationRecord
      #     belongs_to :blog
      #   end
      #
      #   # good
      #   # When you don't want to use the inverse association.
      #   class Blog < ApplicationRecord
      #     has_many(:posts,
      #              -> { order(published_at: :desc) },
      #              inverse_of: false)
      #   end
      #
      # @example
      #   # bad
      #   class Picture < ApplicationRecord
      #     belongs_to :imageable, polymorphic: true
      #   end
      #
      #   class Employee < ApplicationRecord
      #     has_many :pictures, as: :imageable
      #   end
      #
      #   class Product < ApplicationRecord
      #     has_many :pictures, as: :imageable
      #   end
      #
      #   # good
      #   class Picture < ApplicationRecord
      #     belongs_to :imageable, polymorphic: true
      #   end
      #
      #   class Employee < ApplicationRecord
      #     has_many :pictures, as: :imageable, inverse_of: :imageable
      #   end
      #
      #   class Product < ApplicationRecord
      #     has_many :pictures, as: :imageable, inverse_of: :imageable
      #   end
      #
      # @example
      #   # bad
      #   # However, RuboCop can not detect this pattern...
      #   class Physician < ApplicationRecord
      #     has_many :appointments
      #     has_many :patients, through: :appointments
      #   end
      #
      #   class Appointment < ApplicationRecord
      #     belongs_to :physician
      #     belongs_to :patient
      #   end
      #
      #   class Patient < ApplicationRecord
      #     has_many :appointments
      #     has_many :physicians, through: :appointments
      #   end
      #
      #   # good
      #   class Physician < ApplicationRecord
      #     has_many :appointments
      #     has_many :patients, through: :appointments
      #   end
      #
      #   class Appointment < ApplicationRecord
      #     belongs_to :physician, inverse_of: :appointments
      #     belongs_to :patient, inverse_of: :appointments
      #   end
      #
      #   class Patient < ApplicationRecord
      #     has_many :appointments
      #     has_many :physicians, through: :appointments
      #   end
      #
      # @example IgnoreScopes: false (default)
      #   # bad
      #   class Blog < ApplicationRecord
      #     has_many :posts, -> { order(published_at: :desc) }
      #   end
      #
      # @example IgnoreScopes: true
      #   # good
      #   class Blog < ApplicationRecord
      #     has_many :posts, -> { order(published_at: :desc) }
      #   end
      class InverseOf < Base
        SPECIFY_MSG = 'Specify an `:inverse_of` option.'
        NIL_MSG = 'You specified `inverse_of: nil`, you probably meant to use `inverse_of: false`.'
        RESTRICT_ON_SEND = %i[has_many has_one belongs_to].freeze

        def_node_matcher :association_recv_arguments, <<~PATTERN
          (send $_ {:has_many :has_one :belongs_to} _ $...)
        PATTERN

        def_node_matcher :options_from_argument, <<~PATTERN
          (hash $...)
        PATTERN

        def_node_matcher :conditions_option?, <<~PATTERN
          (pair (sym :conditions) !nil)
        PATTERN

        def_node_matcher :through_option?, <<~PATTERN
          (pair (sym :through) !nil)
        PATTERN

        def_node_matcher :polymorphic_option?, <<~PATTERN
          (pair (sym :polymorphic) !nil)
        PATTERN

        def_node_matcher :as_option?, <<~PATTERN
          (pair (sym :as) !nil)
        PATTERN

        def_node_matcher :foreign_key_option?, <<~PATTERN
          (pair (sym :foreign_key) !nil)
        PATTERN

        def_node_matcher :inverse_of_option?, <<~PATTERN
          (pair (sym :inverse_of) !nil)
        PATTERN

        def_node_matcher :inverse_of_nil_option?, <<~PATTERN
          (pair (sym :inverse_of) nil)
        PATTERN

        def on_send(node)
          recv, arguments = association_recv_arguments(node)
          return unless arguments

          with_options = with_options_arguments(recv, node)

          options = arguments.concat(with_options).flat_map do |arg|
            options_from_argument(arg)
          end
          return if options_ignoring_inverse_of?(options)

          return unless scope?(arguments) || options_requiring_inverse_of?(options)

          return if options_contain_inverse_of?(options)

          add_offense(node.loc.selector, message: message(options))
        end

        def scope?(arguments)
          !ignore_scopes? && arguments.any?(&:block_type?)
        end

        def options_requiring_inverse_of?(options)
          required = options.any? do |opt|
            conditions_option?(opt) || foreign_key_option?(opt)
          end

          return required if target_rails_version >= 5.2

          required || options.any? { |opt| as_option?(opt) }
        end

        def options_ignoring_inverse_of?(options)
          options.any? do |opt|
            through_option?(opt) || polymorphic_option?(opt)
          end
        end

        def options_contain_inverse_of?(options)
          options.any? { |opt| inverse_of_option?(opt) }
        end

        def with_options_arguments(recv, node)
          blocks = node.each_ancestor(:block).select do |block|
            block.send_node.command?(:with_options) && same_context_in_with_options?(block.first_argument, recv)
          end
          blocks.flat_map { |n| n.send_node.arguments }
        end

        def same_context_in_with_options?(arg, recv)
          return true if arg.nil? && recv.nil?

          arg && recv && arg.children[0] == recv.children[0]
        end

        private

        def message(options)
          if options.any? { |opt| inverse_of_nil_option?(opt) }
            NIL_MSG
          else
            SPECIFY_MSG
          end
        end

        def ignore_scopes?
          cop_config['IgnoreScopes'] == true
        end
      end
    end
  end
end
