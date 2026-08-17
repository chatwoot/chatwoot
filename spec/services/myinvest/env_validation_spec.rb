require 'rails_helper'
require 'open3'
require 'shellwords'
require 'tempfile'

describe 'deployment/myinvest/scripts/validate.sh' do
  let(:deployment_dir) { Rails.root.join('deployment/myinvest') }
  let(:validate_script) { deployment_dir.join('scripts/validate.sh') }
  let(:base_env) do
    {
      'ENV_FILE' => env_file.path,
      'CADDY_SITE_ADDRESS' => 'support.myinvest-pro.de',
      'CADDY_SITE_SCHEME' => 'https',
      'INGRESS_MODE' => 'direct',
      'ACME_EMAIL' => 'ops@example.invalid',
      'BIND_ADDRESS' => '0.0.0.0',
      'HTTP_PORT' => '80',
      'HTTPS_PORT' => '443',
      'FRONTEND_URL' => 'https://support.myinvest-pro.de',
      'FORCE_SSL' => 'true',
      'ENABLE_ACCOUNT_SIGNUP' => 'false',
      'SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'false',
      'DISABLE_TELEMETRY' => 'true',
      'ENABLE_PUSH_RELAY_SERVER' => 'false',
      'ENABLE_RACK_ATTACK' => 'true',
      'ENABLE_RACK_ATTACK_WIDGET_API' => 'true',
      'RACK_ATTACK_LIMIT' => '300',
      'VIPS_BLOCK_UNTRUSTED' => '1',
      'DEFAULT_LOCALE' => 'de',
      'TZ' => 'Europe/Berlin',
      'LOCAL_SMOKE' => 'false',
      'LOCAL_FAKE_CLAUDE_ANSWER' => '',
      'IMPORT_ID_HMAC_KEY' => 'a' * 32,
      'SECRET_KEY_BASE' => 'a' * 32,
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'a' * 32,
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'a' * 32,
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'a' * 32,
      'POSTGRES_HOST' => 'postgres',
      'POSTGRES_ADMIN_USER' => 'chatwoot_admin',
      'POSTGRES_ADMIN_PASSWORD' => 'a' * 32,
      'POSTGRES_DATABASE' => 'chatwoot',
      'POSTGRES_USERNAME' => 'chatwoot',
      'POSTGRES_PASSWORD' => 'a' * 32,
      'POSTGRES_PORT' => '5432',
      'POSTGRES_STATEMENT_TIMEOUT' => '14s',
      'RAILS_MAX_THREADS' => '5',
      'SIDEKIQ_CONCURRENCY' => '10',
      'REDIS_PASSWORD' => 'a' * 32,
      'REDIS_URL' => 'redis://:a@redis:6379',
      'CLAUDE_AGENT_DATABASE' => 'claude_agent',
      'CLAUDE_AGENT_DATABASE_USER' => 'claude_agent',
      'CLAUDE_AGENT_DATABASE_PASSWORD' => 'a' * 32,
      'CLAUDE_AGENT_DATABASE_URL' => 'postgres://a@postgres/claude_agent',
      'CLAUDE_AGENT_REDIS_URL' => 'redis://:a@redis:6379/1',
      'TENANTS_JSON' => '[]',
      'WEBHOOK_REPLAY_WINDOW_SECONDS' => '300',
      'DELIVERY_RETENTION_SECONDS' => '86400',
      'MAX_BODY_BYTES' => '262144',
      'KNOWLEDGE_MIN_SCORE' => '0.05',
      'KNOWLEDGE_MAX_SOURCES' => '4',
      'ANTHROPIC_PROVIDER' => 'bedrock',
      'ANTHROPIC_MODEL' => 'claude-sonnet-4-5',
      'AWS_REGION' => 'eu-central-1',
      'BEDROCK_MODEL' => 'eu.anthropic.claude-sonnet-4-5-20250929-v1:0',
      'AWS_ACCESS_KEY_ID' => 'a' * 32,
      'AWS_SECRET_ACCESS_KEY' => 'a' * 32,
      'AWS_SESSION_TOKEN' => '',
      'ALLOW_DIRECT_ANTHROPIC' => 'false',
      'ADMIN_NAME' => 'Admin',
      'ADMIN_EMAIL' => 'admin@example.invalid',
      'ADMIN_PASSWORD' => 'a' * 32,
      'MYINVEST_ACCOUNT_NAME' => 'MyInvest Pro',
      'ACADEMY_NEW_ACCOUNT_NAME' => 'Academy Neu',
      'ACADEMY_LEGACY_ACCOUNT_NAME' => 'Academy Alt',
      'MYINVEST_WEBSITE_URL' => 'https://www.myinvest-pro.de',
      'ACADEMY_NEW_WEBSITE_URL' => 'https://www.myinvest-pro.de',
      'ACADEMY_LEGACY_WEBSITE_URL' => 'https://www.myinvest24.de',
      'MAILER_SENDER_EMAIL' => 'support@example.invalid',
      'SMTP_DOMAIN' => 'example.invalid',
      'SMTP_ADDRESS' => 'smtp.example.invalid',
      'SMTP_PORT' => '587',
      'SMTP_USERNAME' => 'user',
      'SMTP_PASSWORD' => 'a' * 32,
      'SMTP_AUTHENTICATION' => 'login',
      'SMTP_ENABLE_STARTTLS_AUTO' => 'true',
      'SMTP_OPENSSL_VERIFY_MODE' => 'peer',
      'ACTIVE_STORAGE_SERVICE' => 's3_compatible',
      'STORAGE_BUCKET_NAME' => 'bucket',
      'STORAGE_ACCESS_KEY_ID' => 'a' * 32,
      'STORAGE_SECRET_ACCESS_KEY' => 'a' * 32,
      'STORAGE_REGION' => 'nbg1',
      'STORAGE_ENDPOINT' => 'http://minio:9000',
      'STORAGE_FORCE_PATH_STYLE' => 'true',
      'STORAGE_LOCAL_MINIO' => 'true',
      'MINIO_ROOT_USER' => 'minio-root',
      'MINIO_ROOT_PASSWORD' => 'a' * 32,
      'DIRECT_UPLOADS_ENABLED' => 'false',
      'RAILS_LOG_TO_STDOUT' => 'true',
      'LOG_LEVEL' => 'error',
      'LOGRAGE_ENABLED' => 'true',
      'INSTALLATION_NAME' => 'MyInvest Support',
      'BRAND_NAME' => 'MyInvest',
      'BACKUP_DIR' => './backups',
      'BACKUP_RETENTION_DAYS' => '14',
      'BACKUP_GPG_RECIPIENT' => 'recipient',
      'BACKUP_OFFSITE_REMOTE' => 'remote:path'
    }
  end
  let(:env_file) { Tempfile.new('.env') }

  before do
    env_file.write(base_env.map { |k, v| "#{k}=#{Shellwords.escape(v)}" }.join("\n"))
    env_file.close
  end

  after do
    env_file.unlink
  end

  def run_validate(extra_env = {})
    env = base_env.merge(extra_env)
    Open3.capture2e(env, validate_script.to_s)
  end

  describe 'Google OAuth paired validation' do
    it 'fails closed when only GOOGLE_OAUTH_CLIENT_ID is set' do
      output, status = run_validate('GOOGLE_OAUTH_CLIENT_ID' => 'client-id')
      expect(status).not_to be_success
      expect(output).to include('GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET must both be set')
    end

    it 'fails closed when only GOOGLE_OAUTH_CLIENT_SECRET is set' do
      output, status = run_validate('GOOGLE_OAUTH_CLIENT_SECRET' => 'client-secret')
      expect(status).not_to be_success
      expect(output).to include('GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET must both be set')
    end

    it 'fails closed when unused GOOGLE_OAUTH_CALLBACK_URL is set' do
      output, status = run_validate(
        'GOOGLE_OAUTH_CLIENT_ID' => 'client-id',
        'GOOGLE_OAUTH_CLIENT_SECRET' => 'client-secret',
        'GOOGLE_OAUTH_CALLBACK_URL' => 'https://support.myinvest-pro.de/google/callback'
      )
      expect(status).not_to be_success
      expect(output).to include('GOOGLE_OAUTH_CALLBACK_URL is unused')
    end
  end
end
