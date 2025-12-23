# frozen_string_literal: true

module DeviseTokenAuth
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      module ClassMethods
        # Define authentication filters and accessor helpers for a group of mappings.
        # These methods are useful when you are working with multiple mappings that
        # share some functionality. They are pretty much the same as the ones
        # defined for normal mappings.
        #
        # Example:
        #
        #   inside BlogsController (or any other controller, it doesn't matter which):
        #     devise_group :blogger, contains: [:user, :admin]
        #
        #   Generated methods:
        #     authenticate_blogger!             # Redirects unless user or admin are signed in
        #     blogger_signed_in?                # Checks whether there is either a user or an admin signed in
        #     current_blogger                   # Currently signed in user or admin
        #     current_bloggers                  # Currently signed in user and admin
        #     render_authenticate_error         # Render error unless user or admin are signed in
        #
        #   Use:
        #     before_action :authenticate_blogger!              # Redirects unless either a user or an admin are authenticated
        #     before_action ->{ authenticate_blogger! :admin }  # Redirects to the admin login page
        #     current_blogger :user                             # Preferably returns a User if one is signed in
        #
        def devise_token_auth_group(group_name, opts = {})
          mappings = "[#{opts[:contains].map { |m| ":#{m}" }.join(',')}]"

          class_eval <<-METHODS, __FILE__, __LINE__ + 1
            def authenticate_#{group_name}!(favourite=nil, opts={})
              unless #{group_name}_signed_in?
                unless current_#{group_name}
                  render_authenticate_error
                end
              end
            end

            def #{group_name}_signed_in?
              !!current_#{group_name}
            end

            def current_#{group_name}(favourite=nil)
              @current_#{group_name} ||= set_group_user_by_token(favourite)
            end
            
            def set_group_user_by_token(favourite)
              mappings = #{mappings}
              mappings.unshift mappings.delete(favourite.to_sym) if favourite
              mappings.each do |mapping|
                current = set_user_by_token(mapping)
                return current if current
              end
              nil
            end

            def current_#{group_name.to_s.pluralize}
              #{mappings}.map do |mapping|
                set_user_by_token(mapping)
              end.compact
            end

            def render_authenticate_error
              return render json: {
                errors: [I18n.t('devise.failure.unauthenticated')]
              }, status: 401
            end

            if respond_to?(:helper_method)
              helper_method(
                "current_#{group_name}",
                "current_#{group_name.to_s.pluralize}",
                "#{group_name}_signed_in?",
                "render_authenticate_error"
              )
            end
          METHODS
        end

        def log_process_action(payload)
          payload[:status] ||= 401 unless payload[:exception]
          super
        end
      end

      # Define authentication filters and accessor helpers based on mappings.
      # These filters should be used inside the controllers as before_actions,
      # so you can control the scope of the user who should be signed in to
      # access that specific controller/action.
      # Example:
      #
      #   Roles:
      #     User
      #     Admin
      #
      #   Generated methods:
      #     authenticate_user!                   # Signs user in or 401
      #     authenticate_admin!                  # Signs admin in or 401
      #     user_signed_in?                      # Checks whether there is a user signed in or not
      #     admin_signed_in?                     # Checks whether there is an admin signed in or not
      #     current_user                         # Current signed in user
      #     current_admin                        # Current signed in admin
      #     user_session                         # Session data available only to the user scope
      #     admin_session                        # Session data available only to the admin scope
      #     render_authenticate_error            # Render error unless user or admin is signed in
      #
      #   Use:
      #     before_action :authenticate_user!  # Tell devise to use :user map
      #     before_action :authenticate_admin! # Tell devise to use :admin map
      #
      def self.define_helpers(mapping) #:nodoc:
        mapping = mapping.name

        class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def authenticate_#{mapping}!(opts={})
            unless current_#{mapping}
              render_authenticate_error
            end
          end

          def #{mapping}_signed_in?
            !!current_#{mapping}
          end

          def current_#{mapping}
            @current_#{mapping} ||= set_user_by_token(:#{mapping})
          end

          def #{mapping}_session
            current_#{mapping} && warden.session(:#{mapping})
          end

          def render_authenticate_error
            return render json: {
              errors: [I18n.t('devise.failure.unauthenticated')]
            }, status: 401
          end
        METHODS

        ActiveSupport.on_load(:action_controller) do
          if respond_to?(:helper_method)
            helper_method(
              "current_#{mapping}",
              "#{mapping}_signed_in?",
              "#{mapping}_session",
              'render_authenticate_error'
            )
          end
        end
      end
    end
  end
end
