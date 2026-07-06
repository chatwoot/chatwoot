# First-boot Super Admin provisioning + baseline hardening for the platform
# operator console (`/super_admin`). Replaces Chatwoot's insecure dev seed
# (`john@acme.inc / Password1!`, db/seeds.rb) with an env-driven, strong-credential
# operator so a deployed instance never ships with a known default.
#
# Idempotent and safe to run on every boot: it creates the operator only when
# missing, never resets an existing password unless explicitly asked, and only
# writes installation configs that changed. Fork-owned (custom/ overlay) →
# upstream merges never touch it. Invoked by `rake fork:super_admin:bootstrap`.
#
# Environment:
#   SUPER_ADMIN_EMAIL                 (required to do anything) operator login email
#   SUPER_ADMIN_PASSWORD              (required) strong password; Chatwoot enforces
#                                     complexity — a weak value fails loud here
#   SUPER_ADMIN_NAME                  (optional) display name, default "Platform Operator"
#   SUPER_ADMIN_ROTATE_PASSWORD=true  reset the password of an EXISTING operator
#   SUPER_ADMIN_REMOVE_DEFAULT_SEED=true  delete the `john@acme.inc` seed admin
#                                     (never the configured operator)
#   SUPER_ADMIN_DISABLE_SIGNUP=true   turn off public self-signup
#                                     (ENABLE_ACCOUNT_SIGNUP=false) — a safe default
module Custom
  class SuperAdminBootstrap
    SEED_ADMIN_EMAIL = 'john@acme.inc'.freeze

    def self.run(env: ENV, logger: Rails.logger)
      new(env: env, logger: logger).run
    end

    def initialize(env: ENV, logger: Rails.logger)
      @env = env
      @logger = logger
    end

    def run
      ensure_super_admin
      remove_default_seed_admin
      apply_security_config
    end

    private

    def ensure_super_admin
      email = presence(@env['SUPER_ADMIN_EMAIL'])
      password = presence(@env['SUPER_ADMIN_PASSWORD'])

      unless email && password
        warn('SUPER_ADMIN_EMAIL / SUPER_ADMIN_PASSWORD not set — skipping Super Admin bootstrap.')
        return
      end

      admin = SuperAdmin.find_or_initialize_by(email: email)

      if admin.new_record?
        admin.name = presence(@env['SUPER_ADMIN_NAME']) || 'Platform Operator'
        admin.password = password
        admin.skip_confirmation!
        admin.save!
        info("Created Super Admin #{email}")
      elsif truthy?(@env['SUPER_ADMIN_ROTATE_PASSWORD'])
        admin.password = password
        admin.save!
        info("Rotated Super Admin password for #{email}")
      else
        info("Super Admin #{email} already present — unchanged (set SUPER_ADMIN_ROTATE_PASSWORD=true to reset).")
      end
    rescue ActiveRecord::RecordInvalid => e
      # Fail loud on a weak/invalid credential — Chatwoot's password policy requires
      # upper + lower + digit + special. Don't leave the instance without an operator
      # silently; surface exactly what to fix (no secret in the message).
      raise "Super Admin bootstrap failed for #{presence(@env['SUPER_ADMIN_EMAIL'])}: #{e.record.errors.full_messages.join(', ')}"
    end

    # Remove the well-known dev seed operator so a deployed instance can't be reached
    # with `john@acme.inc / Password1!`. Opt-in, and never deletes the configured
    # operator even if they happen to reuse that email.
    def remove_default_seed_admin
      return unless truthy?(@env['SUPER_ADMIN_REMOVE_DEFAULT_SEED'])

      configured = presence(@env['SUPER_ADMIN_EMAIL'])
      SuperAdmin.where(email: SEED_ADMIN_EMAIL).where.not(email: configured).find_each do |admin|
        admin.destroy!
        warn("Removed default seed Super Admin #{admin.email}")
      end
    end

    # Baseline hardening Chatwoot already supports: turn off public self-signup so
    # nobody can create tenant accounts without the control plane. Written through the
    # InstallationConfig DB (authoritative over ENV) + cache clear, matching
    # docs/operations/chatwoot-access-lockdown.md. SSO-only login is a separate,
    # tenant-facing control and is intentionally NOT toggled here to avoid lockout.
    def apply_security_config
      return unless truthy?(@env['SUPER_ADMIN_DISABLE_SIGNUP'])

      config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
      if config.value.to_s == 'false'
        info('Public self-signup already disabled.')
        return
      end

      config.value = 'false'
      config.locked = false
      config.save!
      GlobalConfig.clear_cache
      info('Disabled public self-signup (ENABLE_ACCOUNT_SIGNUP=false).')
    end

    def presence(value)
      value.to_s.strip.presence
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def info(message)
      @logger.info("[SuperAdminBootstrap] #{message}")
    end

    def warn(message)
      @logger.warn("[SuperAdminBootstrap] #{message}")
    end
  end
end
