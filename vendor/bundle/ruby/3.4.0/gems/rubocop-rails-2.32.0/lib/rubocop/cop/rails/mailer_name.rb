# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that mailer names end with `Mailer` suffix.
      #
      # Without the `Mailer` suffix it isn't immediately apparent what's a mailer
      # and which views are related to the mailer.
      #
      # @safety
      #   This cop's autocorrection is unsafe because renaming a constant is
      #   always an unsafe operation.
      #
      # @example
      #   # bad
      #   class User < ActionMailer::Base
      #   end
      #
      #   class User < ApplicationMailer
      #   end
      #
      #   # good
      #   class UserMailer < ActionMailer::Base
      #   end
      #
      #   class UserMailer < ApplicationMailer
      #   end
      #
      class MailerName < Base
        extend AutoCorrector

        MSG = 'Mailer should end with `Mailer` suffix.'

        def_node_matcher :mailer_base_class?, <<~PATTERN
          {
            (const (const {nil? cbase} :ActionMailer) :Base)
            (const {nil? cbase} :ApplicationMailer)
          }
        PATTERN

        def_node_matcher :class_definition?, <<~PATTERN
          (class $(const _ !#mailer_suffix?) #mailer_base_class? ...)
        PATTERN

        def_node_matcher :class_new_definition?, <<~PATTERN
          (send (const {nil? cbase} :Class) :new #mailer_base_class?)
        PATTERN

        def on_class(node)
          class_definition?(node) do |name_node|
            add_offense(name_node) do |corrector|
              autocorrect(corrector, name_node)
            end
          end
        end

        def on_send(node)
          return unless class_new_definition?(node)

          casgn_parent = node.each_ancestor(:casgn).first
          return unless casgn_parent

          name = casgn_parent.children[1]
          return if mailer_suffix?(name)

          add_offense(casgn_parent.loc.name) do |corrector|
            autocorrect(corrector, casgn_parent)
          end
        end

        private

        def autocorrect(corrector, node)
          if node.casgn_type?
            name = node.children[1]
            corrector.replace(node.loc.name, "#{name}Mailer")
          else
            name = node.children.last
            corrector.replace(node, "#{name}Mailer")
          end
        end

        def mailer_suffix?(mailer_name)
          mailer_name.to_s.end_with?('Mailer')
        end
      end
    end
  end
end
