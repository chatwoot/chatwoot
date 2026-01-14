# frozen_string_literal: true

# EvolutionApi::InboxProvisioner
#
# Orchestrates the creation of a WhatsApp inbox backed by Evolution API (Baileys).
#
# Flow:
#   1. Creates Evolution instance (without Chatwoot integration)
#   2. Creates Chatwoot Channel::Api with webhook_url pointing to Evolution
#   3. User must scan QR code, then enable integration via separate step
#
# Usage:
#   provisioner = EvolutionApi::InboxProvisioner.new(
#     account: current_account,
#     inbox_name: 'My WhatsApp'
#   )
#   inbox = provisioner.provision!
#
module EvolutionApi
  class InboxProvisioner
    class ProvisioningError < StandardError; end

    # Integration user email pattern (one per installation)
    INTEGRATION_USER_EMAIL = 'evolution-integration@system.local'

    attr_reader :account, :inbox_name, :instance_name

    def initialize(account:, inbox_name:)
      @account = account
      @inbox_name = inbox_name
      @instance_name = generate_instance_name
    end

    # Provisions the complete Evolution-backed inbox
    # @return [Inbox] The created Chatwoot inbox with Evolution metadata
    def provision!
      validate_evolution_enabled!
      validate_inbox_name_uniqueness!
      ensure_integration_user_membership!

      create_evolution_instance!
      inbox = create_chatwoot_inbox!

      inbox
    rescue StandardError => e
      cleanup_on_failure!
      raise ProvisioningError, "Failed to provision Evolution inbox: #{e.message}"
    end

    private

    def validate_evolution_enabled!
      enabled = InstallationConfig.find_by(name: 'EVOLUTION_API_ENABLED')&.value
      raise ProvisioningError, 'Evolution API is not enabled for this installation' unless enabled == true || enabled == 'true'
    end

    # Evolution's Chatwoot integration identifies an inbox by name within an account.
    # If two inboxes share the same name in the same account, Evolution may bind to the
    # wrong inbox (it picks the first match), breaking message routing.
    #
    # Therefore, Evolution-backed inbox names must be unique per account.
    def validate_inbox_name_uniqueness!
      normalized = inbox_name.to_s.strip
      raise ProvisioningError, 'Inbox name is required' if normalized.blank?

      conflict = account.inboxes
                        .where('lower(name) = ?', normalized.downcase)
                        .exists?
      return unless conflict

      raise ProvisioningError,
            'Inbox name already exists in this account. Evolution integration requires a unique inbox name per account.'
    end

    def evolution_client
      @evolution_client ||= EvolutionApi::Client.new
    end

    def generate_instance_name
      # Format: cw-{accountId}-{timestamp}-{random}
      # This ensures uniqueness and helps with debugging
      timestamp = Time.current.to_i
      random_suffix = SecureRandom.hex(4)
      "cw-#{account.id}-#{timestamp}-#{random_suffix}"
    end

    def ensure_integration_user_membership!
      integration_user = find_or_create_integration_user
      ensure_account_admin_membership!(integration_user)
      ensure_access_token!(integration_user)
    end

    def find_or_create_integration_user
      user = User.find_by(email: INTEGRATION_USER_EMAIL)

      return user if user.present?

      # Create the integration user (system-level, no actual login)
      # Generate a strong password that meets all validation requirements
      secure_password = "#{SecureRandom.hex(16)}Aa1!@"

      User.create!(
        email: INTEGRATION_USER_EMAIL,
        name: 'Evolution Integration',
        password: secure_password,
        password_confirmation: secure_password,
        confirmed_at: Time.current,
        type: 'SuperAdmin'
      )
    end

    def ensure_account_admin_membership!(user)
      existing_membership = AccountUser.find_by(user: user, account: account)

      if existing_membership.present?
        existing_membership.update!(role: :administrator) unless existing_membership.administrator?
      else
        AccountUser.create!(
          user: user,
          account: account,
          role: :administrator
        )
      end
    end

    def ensure_access_token!(user)
      user.access_token || user.create_access_token
    end

    def integration_user_token
      user = User.find_by!(email: INTEGRATION_USER_EMAIL)
      user.access_token&.token
    end

    # Returns a Chatwoot URL reachable by Evolution API
    # In development with containerized Evolution, we need the host IP
    def chatwoot_reachable_url
      if Rails.env.development?
        frontend_url = ENV['FRONTEND_URL']
        if frontend_url&.include?('localhost') || frontend_url&.include?('127.0.0.1')
          host_ip = `ipconfig getifaddr en0 2>/dev/null`.strip
          host_ip = '192.168.0.22' if host_ip.blank?
          "http://#{host_ip}:3000"
        else
          frontend_url
        end
      else
        ENV.fetch('FRONTEND_URL', nil) || Rails.application.routes.url_helpers.root_url
      end
    end

    def evolution_api_url
      InstallationConfig.find_by(name: 'EVOLUTION_API_URL')&.value
    end

    def create_evolution_instance!
      # Create instance WITHOUT any Chatwoot config
      # User will enable integration after scanning QR code
      evolution_client.create_instance(instance_name: instance_name)
    end

    def create_chatwoot_inbox!
      # Create the API channel with Evolution metadata and webhook_url
      api_channel = account.api_channels.create!(
        webhook_url: evolution_webhook_url,
        additional_attributes: build_evolution_metadata
      )

      # Create the inbox
      inbox = account.inboxes.create!(
        name: inbox_name,
        channel: api_channel
      )

      Rails.logger.info("Created Evolution inbox: #{inbox.name} (ID: #{inbox.id}, Instance: #{instance_name})")
      inbox
    end

    def evolution_webhook_url
      # This webhook URL allows Chatwoot to send messages to Evolution
      "#{evolution_api_url}/chatwoot/webhook/#{CGI.escape(instance_name)}"
    end

    def build_evolution_metadata
      {
        'evolution_instance_name' => instance_name,
        'evolution_channel' => 'baileys',
        'evolution_url' => evolution_api_url,
        'webhook_verify_token' => generate_webhook_verify_token
      }
    end

    def generate_webhook_verify_token
      SecureRandom.hex(16)
    end

    def cleanup_on_failure!
      evolution_client.delete_instance(instance_name: instance_name)
    rescue StandardError => e
      Rails.logger.error("Failed to cleanup Evolution instance #{instance_name}: #{e.message}")
    end
  end
end

