# frozen_string_literal: true

require 'devise/strategies/database_authenticatable'

module Devise
  module Models
    # Authenticatable Module, responsible for hashing the password and
    # validating the authenticity of a user while signing in.
    #
    # This module defines a `password=` method. This method will hash the argument
    # and store it in the `encrypted_password` column, bypassing any pre-existing
    # `password` column if it exists.
    #
    # == Options
    #
    # DatabaseAuthenticatable adds the following options to +devise+:
    #
    #   * +pepper+: a random string used to provide a more secure hash. Use
    #     `rails secret` to generate new keys.
    #
    #   * +stretches+: the cost given to bcrypt.
    #
    #   * +send_email_changed_notification+: notify original email when it changes.
    #
    #   * +send_password_change_notification+: notify email when password changes.
    #
    # == Examples
    #
    #    User.find(1).valid_password?('password123')         # returns true/false
    #
    module DatabaseAuthenticatable
      extend ActiveSupport::Concern

      included do
        after_update :send_email_changed_notification, if: :send_email_changed_notification?
        after_update :send_password_change_notification, if: :send_password_change_notification?

        attr_reader :password, :current_password
        attr_accessor :password_confirmation
      end

      def initialize(*args, &block)
        @skip_email_changed_notification = false
        @skip_password_change_notification = false
        super
      end

      # Skips sending the email changed notification after_update
      def skip_email_changed_notification!
        @skip_email_changed_notification = true
      end

      # Skips sending the password change notification after_update
      def skip_password_change_notification!
        @skip_password_change_notification = true
      end

      def self.required_fields(klass)
        [:encrypted_password] + klass.authentication_keys
      end

      # Generates a hashed password based on the given value.
      # For legacy reasons, we use `encrypted_password` to store
      # the hashed password.
      def password=(new_password)
        @password = new_password
        self.encrypted_password = password_digest(@password) if @password.present?
      end

      # Verifies whether a password (ie from sign in) is the user password.
      def valid_password?(password)
        Devise::Encryptor.compare(self.class, encrypted_password, password)
      end

      # Set password and password confirmation to nil
      def clean_up_passwords
        self.password = self.password_confirmation = nil
      end

      # Update record attributes when :current_password matches, otherwise
      # returns error on :current_password.
      #
      # This method also rejects the password field if it is blank (allowing
      # users to change relevant information like the e-mail without changing
      # their password). In case the password field is rejected, the confirmation
      # is also rejected as long as it is also blank.
      def update_with_password(params, *options)
        if options.present?
          Devise.deprecator.warn <<-DEPRECATION.strip_heredoc
            [Devise] The second argument of `DatabaseAuthenticatable#update_with_password`
            (`options`) is deprecated and it will be removed in the next major version.
            It was added to support a feature deprecated in Rails 4, so you can safely remove it
            from your code.
          DEPRECATION
        end

        current_password = params.delete(:current_password)

        if params[:password].blank?
          params.delete(:password)
          params.delete(:password_confirmation) if params[:password_confirmation].blank?
        end

        result = if valid_password?(current_password)
          update(params, *options)
        else
          assign_attributes(params, *options)
          valid?
          errors.add(:current_password, current_password.blank? ? :blank : :invalid)
          false
        end

        clean_up_passwords
        result
      end

      # Updates record attributes without asking for the current password.
      # Never allows a change to the current password. If you are using this
      # method, you should probably override this method to protect other
      # attributes you would not like to be updated without a password.
      #
      # Example:
      #
      #   def update_without_password(params, *options)
      #     params.delete(:email)
      #     super(params)
      #   end
      #
      def update_without_password(params, *options)
        if options.present?
          Devise.deprecator.warn <<-DEPRECATION.strip_heredoc
            [Devise] The second argument of `DatabaseAuthenticatable#update_without_password`
            (`options`) is deprecated and it will be removed in the next major version.
            It was added to support a feature deprecated in Rails 4, so you can safely remove it
            from your code.
          DEPRECATION
        end

        params.delete(:password)
        params.delete(:password_confirmation)

        result = update(params, *options)
        clean_up_passwords
        result
      end

      # Destroy record when :current_password matches, otherwise returns
      # error on :current_password. It also automatically rejects
      # :current_password if it is blank.
      def destroy_with_password(current_password)
        result = if valid_password?(current_password)
          destroy
        else
          valid?
          errors.add(:current_password, current_password.blank? ? :blank : :invalid)
          false
        end

        result
      end

      # A callback initiated after successfully authenticating. This can be
      # used to insert your own logic that is only run after the user successfully
      # authenticates.
      #
      # Example:
      #
      #   def after_database_authentication
      #     self.update_attribute(:invite_code, nil)
      #   end
      #
      def after_database_authentication
      end

      # A reliable way to expose the salt regardless of the implementation.
      def authenticatable_salt
        encrypted_password[0,29] if encrypted_password
      end

      # Send notification to user when email changes.
      def send_email_changed_notification
        send_devise_notification(:email_changed, to: devise_email_before_last_save)
      end

      # Send notification to user when password changes.
      def send_password_change_notification
        send_devise_notification(:password_change)
      end

    protected

      # Hashes the password using bcrypt. Custom hash functions should override
      # this method to apply their own algorithm.
      #
      # See https://github.com/heartcombo/devise-encryptable for examples
      # of other hashing engines.
      def password_digest(password)
        Devise::Encryptor.digest(self.class, password)
      end

      def send_email_changed_notification?
        self.class.send_email_changed_notification && devise_saved_change_to_email? && !@skip_email_changed_notification
      end

      def send_password_change_notification?
        self.class.send_password_change_notification && devise_saved_change_to_encrypted_password? && !@skip_password_change_notification
      end

      module ClassMethods
        Devise::Models.config(self, :pepper, :stretches, :send_email_changed_notification, :send_password_change_notification)

        # We assume this method already gets the sanitized values from the
        # DatabaseAuthenticatable strategy. If you are using this method on
        # your own, be sure to sanitize the conditions hash to only include
        # the proper fields.
        def find_for_database_authentication(conditions)
          find_for_authentication(conditions)
        end
      end
    end
  end
end
