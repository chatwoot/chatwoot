require 'svix'

module Api
  module V1
    module Webhooks
      class ClerkController < Api::BaseController
        skip_before_action :authenticate_user!
        skip_before_action :authenticate_access_token!
        skip_before_action :validate_bot_access_token!
        before_action :verify_clerk_webhook

        def create
          case params['type']
          when 'user.created'
            handle_user_created
          when 'user.updated'
            handle_user_updated
          when 'user.deleted'
            handle_user_deleted
          else
            render json: { error: 'Unhandled event type' }, status: :bad_request
          end
        rescue StandardError => e
          Rails.logger.error("Error processing webhook: #{e.message}")
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def webhook_event
          @webhook_event ||= begin
            wh = Svix::Webhook.new(clerk_webhook_secret)
            payload = request.raw_post

            headers = {
              'svix-id' => request.headers['HTTP_SVIX_ID'],
              'svix-timestamp' => request.headers['HTTP_SVIX_TIMESTAMP'],
              'svix-signature' => request.headers['HTTP_SVIX_SIGNATURE']
            }

            Rails.logger.info("Webhook Headers: #{headers}")
            Rails.logger.info("Webhook Payload: #{payload}")

            wh.verify(payload, headers)
            JSON.parse(payload)
          rescue Svix::WebhookVerificationError => e
            Rails.logger.error("Webhook verification failed: #{e.message}")
            raise
          end
        end

        def handle_user_created
          user_data = params['data']
          email = user_data.dig('email_addresses', 0, 'email_address')

          Rails.logger.info("Processing user creation for email: #{email}")
          user = User.find_by(email: email)

          if user
            user.update!(clerk_user_id: user_data['id'])
            render json: { message: 'Existing user linked with Clerk' }, status: :ok
          else
            password = PasswordGeneratorService.generate

            # Create new user and account using AccountBuilder
            user, = AccountBuilder.new(
              account_name: "#{user_data['first_name']}'s Account",
              user_full_name: "#{user_data['first_name']} #{user_data['last_name']}".strip,
              email: email,
              user_password: password,
              locale: I18n.default_locale
            ).perform

            if user
              user.update!(clerk_user_id: user_data['id'])

              UserNotifications::AccountMailer.welcome_with_password(user, password).deliver_later

              render json: { message: 'User created successfully' }, status: :ok
            else
              Rails.logger.error('User creation failed through AccountBuilder')
              render json: { error: 'Failed to create user account' }, status: :unprocessable_entity
            end
          end
        end

        def handle_user_updated
          user_data = params['data']
          email = user_data.dig('email_addresses', 0, 'email_address')

          Rails.logger.info("Processing user update for clerk_id: #{user_data['id']}, email: #{email}")

          # Try to find user by clerk_user_id first, then by email
          user = User.find_by(clerk_user_id: user_data['id']) || User.find_by(email: email)

          return render json: { error: 'User not found' }, status: :not_found unless user

          # Only update if the user was created by Clerk or has no clerk_user_id
          if user.clerk_user_id.present? || user.clerk_user_id.nil?
            if user.update(
              email: email,
              name: "#{user_data['first_name']} #{user_data['last_name']}".strip,
              clerk_user_id: user_data['id']
            )
              render json: { message: 'User updated successfully' }, status: :ok
            else
              Rails.logger.error("User update failed: #{user.errors.full_messages}")
              render json: { error: user.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { message: 'User not managed by Clerk' }, status: :ok
          end
        end

        def handle_user_deleted
          user_data = params['data']
          Rails.logger.info("Processing user deletion for clerk_id: #{user_data['id']}")

          user = User.find_by(clerk_user_id: user_data['id'])
          return render json: { error: 'User not found' }, status: :not_found unless user

          # Delete all accounts where this user is the only member
          user.accounts.each do |account|
            next unless account.users.count == 1

            begin
              account.destroy!
              Rails.logger.info("Deleted account #{account.id} as user #{user.id} was the only member.")
            rescue StandardError => e
              Rails.logger.error("Failed to delete account #{account.id}: #{e.message}")
            end
          end

          if user.destroy
            render json: { message: 'User and associated accounts deleted successfully' }, status: :ok
          else
            Rails.logger.error("User deletion failed: #{user.errors.full_messages}")
            render json: { error: 'Failed to delete user' }, status: :unprocessable_entity
          end
        end

        def clerk_webhook_secret
          secret = ENV.fetch('CLERK_WEBHOOK_SECRET', nil)
          raise 'Missing CLERK_WEBHOOK_SECRET environment variable' if secret.blank?

          secret
        end

        def verify_clerk_webhook
          webhook_event
        rescue StandardError => e
          Rails.logger.error("Clerk webhook verification failed: #{e.message}")
          render json: { error: 'Invalid webhook signature' }, status: :unauthorized
        end
      end
    end
  end
end
