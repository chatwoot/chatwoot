# == Schema Information
#
# Table name: application_configs
#
#  id            :bigint           not null, primary key
#  custom_params :json
#  description   :text
#  last_used_at  :datetime
#  name          :string(100)      not null
#  open_new_tab  :boolean          default(TRUE)
#  status        :string           default("active"), not null
#  url           :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  user_id       :bigint
#
# Indexes
#
#  index_application_configs_on_account_id             (account_id)
#  index_application_configs_on_account_id_and_name    (account_id,name) UNIQUE
#  index_application_configs_on_account_id_and_status  (account_id,status)
#  index_application_configs_on_last_used_at           (last_used_at)
#  index_application_configs_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
# app/models/application_config.rb
class ApplicationConfig < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true # Quem criou a aplicação

  validates :name, presence: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :status, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  before_validation :set_defaults

  def generate_signed_url(current_user, additional_params = {})
    base_params = {
      user_id: current_user.id,
      account_id: account.id,
      email: current_user.email,
      name: current_user.name,
      locale: current_user.ui_language || 'en',
      timestamp: Time.current.to_i,
      token: generate_access_token(current_user)
    }

    # Merge com parâmetros customizados se existirem
    base_params.merge!(custom_params) if custom_params.present?

    # Merge com parâmetros adicionais
    base_params.merge!(additional_params) if additional_params.present?

    # Construir URL
    uri = URI.parse(url)
    existing_params = URI.decode_www_form(uri.query || '')
    new_params = existing_params + base_params.to_a
    uri.query = URI.encode_www_form(new_params)

    uri.to_s
  end

  def update_last_used!
    update_column(:last_used_at, Time.current)
  end

  def recently_used?
    last_used_at && last_used_at > 30.days.ago
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.open_new_tab = true if open_new_tab.nil?
  end

  def generate_access_token(current_user)
    # Gerar um token JWT simples para verificação
    payload = {
      user_id: current_user.id,
      account_id: account.id,
      application_id: id,
      exp: 1.hour.from_now.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end
end
