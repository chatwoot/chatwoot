# == Schema Information
#
# Table name: account_email_oauth_apps
#
#  id            :bigint           not null, primary key
#  client_id     :text
#  client_secret :text
#  provider      :string           not null
#  redirect_uri  :string
#  settings      :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  index_account_email_oauth_apps_on_account_id_and_provider  (account_id,provider) UNIQUE
#

# Credenciais do app OAuth (Azure/Google) que o cliente cadastra POR CONTA.
# Quando a conta não tem o seu próprio app, o resolver cai no app global
# (super admin) — é o modelo híbrido: simplicidade do global + visão por conta.
class AccountEmailOauthApp < ApplicationRecord
  belongs_to :account

  PROVIDERS = %w[microsoft google].freeze
  # Tenant do Microsoft Identity: GUID do diretório, domínio verificado ou os
  # literais do Identity Platform. Whitelist de formato — o valor entra em URL
  # (login.microsoftonline.com/<tenant>/...), então nada fora disso passa.
  TENANT_ID_FORMAT = /\A(?:common|organizations|consumers|\h{8}-\h{4}-\h{4}-\h{4}-\h{12}|[a-z0-9][a-z0-9.-]*\.[a-z]{2,})\z/i

  # Apps single-tenant (AADSTS50194 no /common) cadastram o tenant aqui;
  # vazio = /common (apps multi-tenant), comportamento original.
  store_accessor :settings, :tenant_id

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :account_id }
  # id e secret andam juntos — evita app parcial que misturaria com o global.
  validates :client_id, presence: true
  validates :client_secret, presence: true
  validates :tenant_id, format: { with: TENANT_ID_FORMAT }, allow_blank: true

  # Secret nunca em texto puro quando a instância tem criptografia configurada
  # (mesmo padrão de Channel::Email#imap_password).
  encrypts :client_secret if Chatwoot.encryption_configured?
end
