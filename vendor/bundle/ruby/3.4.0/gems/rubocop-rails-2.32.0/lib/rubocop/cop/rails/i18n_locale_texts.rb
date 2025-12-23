# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces use of I18n and locale files instead of locale specific strings.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #     validates :email, presence: { message: "must be present" }
      #   end
      #
      #   # good
      #   # config/locales/en.yml
      #   # en:
      #   #   activerecord:
      #   #     errors:
      #   #       models:
      #   #         user:
      #   #           blank: "must be present"
      #
      #   class User < ApplicationRecord
      #     validates :email, presence: true
      #   end
      #
      #   # bad
      #   class PostsController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to root_path, notice: "Post created!"
      #     end
      #   end
      #
      #   # good
      #   # config/locales/en.yml
      #   # en:
      #   #   posts:
      #   #     create:
      #   #       success: "Post created!"
      #
      #   class PostsController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to root_path, notice: t(".success")
      #     end
      #   end
      #
      #   # bad
      #   class UserMailer < ApplicationMailer
      #     def welcome(user)
      #       mail(to: user.email, subject: "Welcome to My Awesome Site")
      #     end
      #   end
      #
      #   # good
      #   # config/locales/en.yml
      #   # en:
      #   #   user_mailer:
      #   #     welcome:
      #   #       subject: "Welcome to My Awesome Site"
      #
      #   class UserMailer < ApplicationMailer
      #     def welcome(user)
      #       mail(to: user.email)
      #     end
      #   end
      #
      class I18nLocaleTexts < Base
        MSG = 'Move locale texts to the locale files in the `config/locales` directory.'

        RESTRICT_ON_SEND = %i[validates redirect_to redirect_back []= mail].freeze

        def_node_search :validation_message, <<~PATTERN
          (pair (sym :message) $str)
        PATTERN

        def_node_search :redirect_to_flash, <<~PATTERN
          (pair (sym {:notice :alert}) $str)
        PATTERN

        def_node_matcher :flash_assignment?, <<~PATTERN
          (send
            {
              (send nil? :flash)
              (send (send nil? :flash) :now)
            } :[]= _ $str)
        PATTERN

        def_node_search :mail_subject, <<~PATTERN
          (pair (sym :subject) $str)
        PATTERN

        def on_send(node)
          case node.method_name
          when :validates
            validation_message(node) do |text_node|
              add_offense(text_node)
            end
            return
          when :redirect_to, :redirect_back
            text_node = redirect_to_flash(node).to_a.last
          when :[]=
            text_node = flash_assignment?(node)
          when :mail
            text_node = mail_subject(node).to_a.last
          end

          add_offense(text_node) if text_node
        end
      end
    end
  end
end
