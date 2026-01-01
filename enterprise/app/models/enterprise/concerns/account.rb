module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
    has_many :applied_slas, dependent: :destroy_async
    has_many :custom_roles, dependent: :destroy_async
    has_many :agent_capacity_policies, dependent: :destroy_async

    has_many :companies, dependent: :destroy_async
    has_many :voice_channels, dependent: :destroy_async, class_name: '::Channel::Voice'

    has_one :saml_settings, dependent: :destroy_async, class_name: 'AccountSamlSettings'
    has_one :whatsapp_settings, dependent: :destroy_async, class_name: 'AccountWhatsappSettings'
  end
end
